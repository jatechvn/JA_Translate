// lib/modules/api_client.dart
// Nvidia Chat Completions streaming client supporting HTTP stream parsing and proxy options

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logging/logging.dart';
import 'app_config.dart';
import 'llama_service.dart';
import 'ocr_service.dart';
import 'translation_cache.dart';

final _logger = Logger('ApiClient');

class ApiClient {
  /// Guess mime type based on file extension to avoid third-party dependencies
  static String _guessMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
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
        _logger.info(
            'Cache hit for text: ${text.substring(0, text.length > 20 ? 20 : text.length)}...');
        final words = cachedResult.split(' ');
        for (var i = 0; i < words.length; i++) {
          yield words[i] + (i == words.length - 1 ? '' : ' ');
          await Future.delayed(
              const Duration(milliseconds: 15)); // typing simulation
        }
        return;
      }
    }
    final isLocal = AppConfig.isLocalAi;
    final String apiKey;
    final String apiBase;
    var model = '';
    final double temperature;

    var textToTranslate = text;

    // Multi-tier Vision: If Local AI has no mmproj, run Windows Native OCR first
    if (isLocal && imagePaths.isNotEmpty) {
      final hasProjector = LlamaService.hasLocalVisionProjector();
      if (!hasProjector) {
        _logger.info(
            'Local AI without mmproj: Extracting text using Windows Native OCR...');
        final ocrResults = <String>[];
        for (final imgPath in imagePaths) {
          final ocrText = await OcrService.recognizeText(imgPath);
          if (ocrText != null && ocrText.trim().isNotEmpty) {
            ocrResults.add(ocrText.trim());
          }
        }

        if (ocrResults.isEmpty && textToTranslate.trim().isEmpty) {
          yield '[Không tìm thấy văn bản trong hình ảnh. Vui lòng thử ảnh rõ nét hơn hoặc dùng Cloud Vision]';
          return;
        }

        textToTranslate = [
          if (textToTranslate.trim().isNotEmpty) textToTranslate.trim(),
          ...ocrResults,
        ].join('\n\n');
      }
    }

    if (isLocal) {
      final port = AppConfig.localLlamaPort;
      final ggufModel = AppConfig.localGgufModel;

      final isRunning = await LlamaService.isServerRunning(port: port);
      if (!isRunning) {
        final started = await LlamaService().startServer(
          modelFileName: ggufModel,
          port: port,
          threads: AppConfig.localThreads,
        );
        if (!started) {
          yield '[Lỗi: Không thể khởi động llama-server local. Vui lòng kiểm tra model GGUF trong thư mục models/ hoặc vào Cài đặt AI Local để tải]';
          return;
        }
      }
      apiBase = 'http://127.0.0.1:$port/v1';
      model = ggufModel;
      apiKey = '';
      temperature = double.tryParse(
              AppConfig.get('LOCAL_AI', 'temperature', defaultValue: '0.2')) ??
          0.2;
    } else {
      apiKey = AppConfig.get('NVIDIA', 'api_key');
      apiBase = AppConfig.get('NVIDIA', 'api_base',
          defaultValue: 'https://integrate.api.nvidia.com/v1');
      model = AppConfig.get('NVIDIA', 'model',
          defaultValue: 'qwen/qwen2.5-7b-instruct');
      temperature = 0.1;
    }

    final visionModel = AppConfig.get('NVIDIA', 'vision_model',
        defaultValue: 'meta/llama-3.2-11b-vision-instruct');

    final invokeUrl = Uri.parse('$apiBase/chat/completions');

    final headers = {
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
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

    final isVisionCloud = !isLocal && imagePaths.isNotEmpty;
    final systemContent = isVisionCloud
        ? 'You are an expert OCR and translation assistant. Carefully examine the provided image(s), read and extract all visible text, and translate it into $targetName accurately and naturally. Output ONLY the translated text without any introductory remarks, explanations, markdown quotes, or conversational filler.'
        : (isLocal
            ? 'You are an expert multilingual translator. Translate from $sourceName to $targetName accurately and naturally. Output ONLY the translation result without any explanation, markdown quote, or extra conversational text.'
            : 'You are a professional translator. Translate from $sourceName to $targetName. Maintain meaning and formatting. Only output the translation result.');

    final userMsgContent = <Map<String, dynamic>>[];
    if (textToTranslate.isNotEmpty) {
      userMsgContent.add({'type': 'text', 'text': textToTranslate});
    }

    // Only attach image_url if running on Cloud or if local model has mmproj support
    if (imagePaths.isNotEmpty &&
        (!isLocal || LlamaService.hasLocalVisionProjector())) {
      if (!isLocal) {
        model = visionModel;
      }
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
      'temperature': temperature,
      'top_p': 1.0,
      'max_tokens': 4096,
      'stream': true,
      if (!isLocal) 'chat_template_kwargs': {'enable_thinking': false}
    };

    _logger.info(
        'Sending request to $invokeUrl with model: $model (Local: $isLocal)');

    final client = _getClient();
    final request = http.Request('POST', invokeUrl);
    request.headers.addAll(headers);
    request.body = jsonEncode(payload);

    try {
      final response =
          await client.send(request).timeout(const Duration(seconds: 180));

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        _logger.severe('API Error (${response.statusCode}): $body');
        if (body.contains('image input is not supported') ||
            body.contains('mmproj')) {
          yield '[Lỗi: Model Local hiện tại chưa hỗ trợ nhận diện ảnh trực tiếp. Vui lòng thử lại hoặc cấu hình Cloud AI]';
        } else if (response.statusCode == 401 ||
            body.contains('Unauthorized')) {
          yield '[Lỗi 401: API Key Cloud không hợp lệ hoặc đã hết hạn. Vui lòng kiểm tra lại trong Cài đặt Cloud AI]';
        } else {
          yield 'Error: API returned status ${response.statusCode} - $body';
        }
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
        await TranslationCache.set(
            text, sourceLang, targetLang, fullTextBuffer.toString());
      }
    } catch (e) {
      _logger.severe('Request failed: $e');
      if (isLocal &&
          (e is SocketException ||
              e.toString().contains('Connection refused') ||
              e.toString().contains('ClientException'))) {
        yield 'Lỗi kết nối Local AI: Không thể kết nối tới Llama Server tại $apiBase.\n\nVui lòng đảm bảo model GGUF đã được tải trong thư mục models/ hoặc khởi động server trong Cài đặt Local AI.';
      } else {
        yield 'Error: $e';
      }
    } finally {
      client.close();
    }
  }

  /// Check if the Local AI endpoint is accessible
  static Future<bool> checkLocalAiHealth({String? endpoint}) async {
    if (endpoint == null) {
      return await LlamaService.isServerRunning(port: AppConfig.localLlamaPort);
    }
    try {
      final uri = Uri.parse('$endpoint/models');
      final client = _getClient();
      final response =
          await client.get(uri).timeout(const Duration(seconds: 3));
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch list of models currently installed in models/ directory
  static Future<List<String>> getInstalledLocalModels(
      {String? endpoint}) async {
    return LlamaService.getInstalledGgufModels();
  }

  /// Ensure embedded llama.cpp local AI server is running
  static Future<bool> ensureLocalAiRunning() async {
    if (await checkLocalAiHealth()) return true;
    final port = AppConfig.localLlamaPort;
    final model = AppConfig.localGgufModel;
    final threads = AppConfig.localThreads;
    return await LlamaService().startServer(
      modelFileName: model.isNotEmpty ? model : null,
      port: port,
      threads: threads,
    );
  }

  /// Backward-compatibility alias
  static Future<bool> ensureOllamaRunning() => ensureLocalAiRunning();

  /// Test connection to Cloud AI Provider (NVIDIA / OpenAI / Groq / etc.)
  static Future<Map<String, dynamic>> testCloudConnection({
    required String apiKey,
    required String apiBase,
    required String model,
  }) async {
    final client = _getClient();
    final cleanBase = apiBase.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanBase/chat/completions');

    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'user', 'content': 'Hi'}
              ],
              'max_tokens': 5,
            }),
          )
          .timeout(const Duration(seconds: 12));

      client.close();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'OK (${response.statusCode})',
        };
      } else {
        String errMsg = 'HTTP ${response.statusCode}';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody['error'] != null) {
            errMsg += ': ${errBody['error']['message'] ?? errBody['error']}';
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            errMsg +=
                ': ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}';
          }
        }
        return {
          'success': false,
          'message': errMsg,
        };
      }
    } catch (e) {
      client.close();
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
