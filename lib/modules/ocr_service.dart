// lib/modules/ocr_service.dart
// Native Windows OCR service bridge via ocr_processor.py

import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';

final _logger = Logger('OcrService');

class OcrService {
  /// Locates python executable
  static String _getPythonExecutable() {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final bundledPath = '$exeDir/data/python/python.exe';
      if (File(bundledPath).existsSync()) return bundledPath;
    } catch (_) {}

    const devBundledPath = 'python/python.exe';
    if (File(devBundledPath).existsSync()) return devBundledPath;

    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final pyDir = Directory('$localAppData\\Programs\\Python');
      if (pyDir.existsSync()) {
        try {
          for (final dir in pyDir.listSync()) {
            if (dir is Directory &&
                dir.path.toLowerCase().contains('python3')) {
              final pyExe = '${dir.path}\\python.exe';
              if (File(pyExe).existsSync()) return pyExe;
            }
          }
        } catch (_) {}
      }
    }

    for (final ver in ['312', '311', '310', '39', '38']) {
      final cPy = 'C:\\Python$ver\\python.exe';
      if (File(cPy).existsSync()) return cPy;
    }

    return 'python';
  }

  /// Resolve path to ocr_processor.py
  static String? _getOcrScriptPath() {
    const devPath = 'lib/modules/ocr_processor.py';
    if (File(devPath).existsSync()) return devPath;

    const devAsset = 'data/flutter_assets/lib/modules/ocr_processor.py';
    if (File(devAsset).existsSync()) return devAsset;

    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final distPath =
          '$exeDir/data/flutter_assets/lib/modules/ocr_processor.py';
      if (File(distPath).existsSync()) return distPath;
    } catch (_) {}

    return null;
  }

  /// Recognize text from image file using Windows Native OCR
  static Future<String?> recognizeText(String imagePath,
      {String lang = 'en'}) async {
    final scriptPath = _getOcrScriptPath();
    if (scriptPath == null) {
      _logger.warning('ocr_processor.py not found');
      return null;
    }

    final pythonExe = _getPythonExecutable();
    try {
      final res = await Process.run(pythonExe, [scriptPath, imagePath, lang]);
      if (res.exitCode == 0) {
        final out = res.stdout.toString().trim();
        final lines = out.split('\n');
        for (final line in lines.reversed) {
          final trimmed = line.trim();
          if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
            final json = jsonDecode(trimmed) as Map<String, dynamic>;
            if (json['success'] == true) {
              return json['text'] as String?;
            }
          }
        }
      } else {
        _logger.warning(
            'OCR process returned exit code ${res.exitCode}: ${res.stderr}');
      }
    } catch (e) {
      _logger.severe('Failed to run OCR: $e');
    }
    return null;
  }
}
