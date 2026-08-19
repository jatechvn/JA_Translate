// lib/modules/api_client.dart
// Nvidia Chat Completions streaming client supporting HTTP stream parsing and proxy options

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logging/logging.dart';
import 'app_config.dart';
import 'translation_cache.dart';

final _logger = Logger('ApiClient');

class ApiClient {
  /// Guess mime type based on file extension to avoid third-party dependencies
  static String _guessMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'webp': return 'image/webp';
      case 'bmp': return 'image/bmp';
      default: return 'image/jpeg';
    }
  }

  /// Create and configure the HttpClient with optional proxy credentials
  static http.Client _getClient() {
    final proxyEnabled = AppConfig.get('PROXY', 'enabled') == 'true';
    final host = AppConfig.get('PROXY', 'host');
    final port = AppConfig.get('PROXY', 'port');
    final user = AppConfig.get('PROXY', 'user');
    final pass = AppConfig.get('PROXY', 'pass');

    final innerClient = HttpClient();

    if (proxyEnabled && host.isNotEmpty && port.isNotEmpty) {
      _logger.info('Configuring client with HTTP Proxy: $host:$port');
      innerClient.findProxy = (uri) {
        return 'PROXY $host:$port';
      };
      if (user.isNotEmpty && pass.isNotEmpty) {
        innerClient.addCredentials(
          Uri.parse('http://$host:$port'),
          '',
          HttpClientBasicCredentials(user, pass),
        );
        innerClient.addCredentials(
          Uri.parse('https://$host:$port'),
          '',
          HttpClientBasicCredentials(user, pass),
        );
      }
    }

    return IOClient(innerClient);
  }

  /// Send streaming API request to Nvidia Completions endpoint
  static Stream<String> translateStream({
    required String text,
    required String sourceLang,
    required String targetLang,
    required List<String> imagePaths,
  }) async* {
    // Check local cache first (only for text translations without images)
    if (imagePaths.isEmpty) {
      final cachedResult = TranslationCache.get(text, sourceLang, targetLang);
      if (cachedResult != null) {
        _logger.info('Cache hit for text: ${text.substring(0, text.length > 20 ? 20 : text.length)}...');
        final words = cachedResult.split(' ');
        for (var i = 0; i < words.length; i++) {
          yield words[i] + (i == words.length - 1 ? '' : ' ');
          await Future.delayed(const Duration(milliseconds: 15)); // typing simulation
        }
        return;
      }
    }
    final apiKey = AppConfig.get('NVIDIA', 'api_key');
    final apiBase = AppConfig.get('NVIDIA', 'api_base', defaultValue: 'https://integrate.api.nvidia.com/v1');
    var model = AppConfig.get('NVIDIA', 'model', defaultValue: 'google/gemma-4-31b-it');
    final visionModel = AppConfig.get('NVIDIA', 'vision_model', defaultValue: 'meta/llama-3.2-90b-vision-instruct');

    final invokeUrl = Uri.parse('$apiBase/chat/completions');

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Accept': 'text/event-stream',
      'Content-Type': 'application/json',
    };

    final langMap = {
      'VN': 'Vietnamese',
      'ENG': 'English',
      'CN': 'Chinese (Simplified)',
    };

    final targetName = langMap[targetLang] ?? 'Vietnamese';
    final sourceName = langMap[sourceLang] ?? 'Auto-detect';
    final systemContent = 'You are a professional translator. Translate from $sourceName to $targetName. Maintain meaning and formatting. Only output the translation result.';

    final userMsgContent = <Map<String, dynamic>>[];
    if (text.isNotEmpty) {
      userMsgContent.add({'type': 'text', 'text': text});
    }

    if (imagePaths.isNotEmpty) {
      model = visionModel;
      for (final path in imagePaths) {
        try {
          final file = File(path);
          if (!file.existsSync()) continue;
          final mimeType = _guessMimeType(path);
          final bytes = file.readAsBytesSync();
          final base64String = base64Encode(bytes);
          userMsgContent.add({
            'type': 'image_url',
            'image_url': {
              'url': 'data:$mimeType;base64,$base64String',
            }
          });
        } catch (e) {
          _logger.severe('Error reading image $path: $e');
        }
      }
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemContent}
    ];

    if (userMsgContent.isNotEmpty) {
      if (userMsgContent.length == 1 && userMsgContent[0]['type'] == 'text') {
        messages.add({'role': 'user', 'content': userMsgContent[0]['text']});
      } else {
        messages.add({'role': 'user', 'content': userMsgContent});
      }
    }

    final payload = {
      'model': model,
      'messages': messages,
      'temperature': 0.1,
      'top_p': 1.0,
      'max_tokens': 4096,
      'stream': true,
      'chat_template_kwargs': {'enable_thinking': false}
    };

    _logger.info('Sending request to $invokeUrl with model: $model');

    final client = _getClient();
    final request = http.Request('POST', invokeUrl);
    request.headers.addAll(headers);
    request.body = jsonEncode(payload);

    try {
      final response = await client.send(request).timeout(const Duration(seconds: 180));
      
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        _logger.severe('API Error (${response.statusCode}): $body');
        yield 'Error: API returned status ${response.statusCode} - $body';
        client.close();
        return;
      }

      final lineStream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      final fullTextBuffer = StringBuffer();

      await for (final line in lineStream) {
        if (line.isEmpty) continue;
        var decoded = line.trim();
        if (decoded.startsWith('data: ')) {
          decoded = decoded.substring(6);
        }
        if (decoded == '[DONE]') break;
        try {
          final data = jsonDecode(decoded);
          final choice = data['choices']?[0] ?? {};
          final delta = choice['delta'] ?? {};
          final content = delta['content'] ?? '';
          if (content.isNotEmpty) {
            fullTextBuffer.write(content);
            yield content;
          }
        } catch (_) {
          continue;
        }
      }

      // Save to cache after successful completion
      if (imagePaths.isEmpty && fullTextBuffer.isNotEmpty) {
        await TranslationCache.set(text, sourceLang, targetLang, fullTextBuffer.toString());
      }
    } catch (e) {
      _logger.severe('Request failed: $e');
      yield 'Error: $e';
    } finally {
      client.close();
    }
  }
}
