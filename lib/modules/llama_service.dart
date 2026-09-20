// lib/modules/llama_service.dart
// Embedded high-performance llama.cpp server manager and GGUF model downloader

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';

class LlamaModelPreset {
  final String name;
  final String fileName;
  final String downloadUrl;
  final String description;
  final String sizeLabel;

  const LlamaModelPreset({
    required this.name,
    required this.fileName,
    required this.downloadUrl,
    required this.description,
    required this.sizeLabel,
  });
}

class LlamaService {
  static final LlamaService _instance = LlamaService._internal();
  factory LlamaService() => _instance;
  LlamaService._internal();

  static const List<LlamaModelPreset> presets = [
    LlamaModelPreset(
      name: 'Qwen2.5-1.5B (Khuyên dùng)',
      fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
      description:
          'Tối ưu tốc độ cao nhất và chuẩn xác nhất cho máy 8GB RAM. Chiếm ~1.1GB RAM.',
      sizeLabel: '986 MB',
    ),
    LlamaModelPreset(
      name: 'Qwen2.5-0.5B (Siêu nhẹ)',
      fileName: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      description: 'Cực nhẹ, tốc độ dịch tức thì. Chiếm ~500MB RAM.',
      sizeLabel: '390 MB',
    ),
    LlamaModelPreset(
      name: 'Qwen2.5-3B (Chất lượng cao)',
      fileName: 'qwen2.5-3b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf',
      description:
          'Bản dịch chi tiết, câu từ học thuật mượt mà hơn. Chiếm ~2.3GB RAM.',
      sizeLabel: '1.93 GB',
    ),
    LlamaModelPreset(
      name: 'Qwen2-VL-2B (Dịch Ảnh & Chữ Local)',
      fileName: 'qwen2-vl-2b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2-VL-2B-Instruct-GGUF/resolve/main/qwen2-vl-2b-instruct-q4_k_m.gguf',
      description:
          'Hỗ trợ nhận diện dịch trực tiếp cả hình ảnh và văn bản offline. Chiếm ~2.1GB RAM.',
      sizeLabel: '1.78 GB',
    ),
  ];

  Process? _serverProcess;
  bool _isStarting = false;

  /// Resolve path to the app's models/ directory
  static String getModelsDirectory() {
    // 1. Check relative to executable (release build)
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final distModels = '$exeDir/models';
      if (Directory(distModels).existsSync()) return distModels;
    } catch (_) {}

    // 2. Check project root (dev)
    const devModels = 'models';
    if (!Directory(devModels).existsSync()) {
      try {
        Directory(devModels).createSync(recursive: true);
      } catch (_) {}
    }
    return devModels;
  }

  /// Resolve path to bin/llama-server.exe
  static String? getLlamaServerExecutable() {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final distServer = '$exeDir/bin/llama-server.exe';
      if (File(distServer).existsSync()) return distServer;
    } catch (_) {}

    const devServer = 'bin/llama-server.exe';
    if (File(devServer).existsSync()) return devServer;

    return null;
  }

  /// List all .gguf files inside models/
  static List<String> getInstalledGgufModels() {
    final dirPath = getModelsDirectory();
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];

    try {
      return dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.gguf'))
          .map((f) => f.path.split(Platform.pathSeparator).last)
          .toList();
    } catch (e) {
      debugPrint('Error reading models directory: $e');
      return [];
    }
  }

  /// Open models/ directory in Windows File Explorer
  static void openModelsFolder() {
    final dirPath = getModelsDirectory();
    Process.run('explorer.exe', [dirPath.replaceAll('/', '\\')]);
  }

  /// Check if llama-server is currently healthy
  static Future<bool> isServerRunning({int port = 8080}) async {
    try {
      final client = http.Client();
      final response = await client
          .get(Uri.parse('http://127.0.0.1:$port/health'))
          .timeout(const Duration(milliseconds: 1200));
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Check if an mmproj projector exists in models/ for vision support
  static bool hasLocalVisionProjector() {
    final dir = Directory(getModelsDirectory());
    if (!dir.existsSync()) return false;
    try {
      return dir.listSync().whereType<File>().any((f) {
        final lower = f.path.toLowerCase();
        return lower.endsWith('.gguf') && lower.contains('mmproj');
      });
    } catch (_) {
      return false;
    }
  }

  /// Start the background llama-server.exe process
  Future<bool> startServer({
    String? modelFileName,
    int port = 8080,
    int? threads,
  }) async {
    if (await isServerRunning(port: port)) return true;
    if (_isStarting) return false;
    _isStarting = true;

    final serverExe = getLlamaServerExecutable();
    if (serverExe == null) {
      debugPrint('llama-server.exe not found in bin/');
      _isStarting = false;
      return false;
    }

    final modelsDir = getModelsDirectory();
    final modelName = modelFileName ??
        AppConfig.get('LOCAL_AI', 'gguf_model',
            defaultValue: 'qwen2.5-1.5b-instruct-q4_k_m.gguf');
    final modelPath = '$modelsDir/$modelName';

    if (!File(modelPath).existsSync()) {
      debugPrint('Model file does not exist: $modelPath');
      _isStarting = false;
      return false;
    }

    final threadCount = threads ??
        int.tryParse(AppConfig.get('LOCAL_AI', 'threads', defaultValue: '4')) ??
        4;

    // Check for optional mmproj file in models/ directory
    String? mmprojPath;
    try {
      final mDir = Directory(modelsDir);
      if (mDir.existsSync()) {
        for (final f in mDir.listSync().whereType<File>()) {
          final lower = f.path.toLowerCase();
          if (lower.endsWith('.gguf') && lower.contains('mmproj')) {
            mmprojPath = f.path;
            break;
          }
        }
      }
    } catch (_) {}

    try {
      final args = [
        '-m',
        modelPath,
        if (mmprojPath != null) ...['-mm', mmprojPath],
        '-c',
        '2048',
        '-t',
        '$threadCount',
        '--host',
        '127.0.0.1',
        '--port',
        '$port',
      ];

      debugPrint('Starting llama-server: $serverExe ${args.join(" ")}');

      _serverProcess = await Process.start(
        serverExe,
        args,
        workingDirectory: File(serverExe).parent.path,
        mode: ProcessStartMode.detached,
      );

      // Wait up to 10 seconds for server to be healthy
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (await isServerRunning(port: port)) {
          _isStarting = false;
          return true;
        }
      }
    } catch (e) {
      debugPrint('Failed to start llama-server: $e');
    }

    _isStarting = false;
    return await isServerRunning(port: port);
  }

  /// Stop running llama-server
  Future<void> stopServer() async {
    try {
      _serverProcess?.kill();
      _serverProcess = null;
      await Process.run('taskkill', ['/IM', 'llama-server.exe', '/F']);
    } catch (_) {}
  }

  /// Stream download GGUF model directly into app models/ folder
  static Stream<Map<String, dynamic>> downloadModelStream({
    required String downloadUrl,
    required String fileName,
  }) async* {
    final modelsDir = getModelsDirectory();
    final targetPath = '$modelsDir/$fileName';
    final partPath = '$targetPath.part';

    final client = http.Client();
    final request = http.Request('GET', Uri.parse(downloadUrl));
    request.headers['User-Agent'] = 'Mozilla/5.0';

    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        yield {
          'status': 'error',
          'error': 'Server returned HTTP ${response.statusCode}',
          'percent': 0.0,
          'done': true,
        };
        client.close();
        return;
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;
      final file = File(partPath);
      final sink = file.openWrite();

      var lastUpdate = DateTime.now();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        final now = DateTime.now();
        if (now.difference(lastUpdate).inMilliseconds > 200 ||
            receivedBytes == totalBytes) {
          lastUpdate = now;
          final double percent = totalBytes > 0
              ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
              : 0.0;
          yield {
            'status': 'downloading',
            'completed': receivedBytes,
            'total': totalBytes,
            'percent': percent,
            'done': false,
          };
        }
      }

      await sink.flush();
      await sink.close();

      // Rename .part to .gguf
      if (file.existsSync()) {
        if (File(targetPath).existsSync()) {
          File(targetPath).deleteSync();
        }
        file.renameSync(targetPath);
      }

      yield {
        'status': 'success',
        'completed': receivedBytes,
        'total': totalBytes,
        'percent': 1.0,
        'done': true,
        'savedPath': targetPath,
      };
    } catch (e) {
      yield {
        'status': 'error',
        'error': e.toString(),
        'percent': 0.0,
        'done': true,
      };
    } finally {
      client.close();
    }
  }
}
