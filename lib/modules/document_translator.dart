import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'api_client.dart';
import 'translation_cache.dart';

class DocumentTranslationProgress {
  final int currentChunk;
  final int totalChunks;
  final double percentage;
  final String status;
  final String? resultText;
  final String? error;

  DocumentTranslationProgress({
    required this.currentChunk,
    required this.totalChunks,
    required this.percentage,
    required this.status,
    this.resultText,
    this.error,
  });
}

class DocumentFileStats {
  final int charCount;
  final int wordCount;
  DocumentFileStats({required this.charCount, required this.wordCount});
}

class DocumentTranslator {
  /// Analyzes file and returns stats (character and word count)
  static Future<DocumentFileStats> getFileStats(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File not found');
    }
    final ext = filePath.split('.').last.toLowerCase();
    
    if (ext == 'txt' || ext == 'md') {
      final text = file.readAsStringSync(encoding: utf8);
      final charCount = text.length;
      final wordCount = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
      return DocumentFileStats(charCount: charCount, wordCount: wordCount);
    }
    
    // Resolve modules directory
    String modulesDir = 'lib/modules';
    if (!Directory(modulesDir).existsSync()) {
      modulesDir = 'data/flutter_assets/lib/modules';
    }
    if (!Directory(modulesDir).existsSync()) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      modulesDir = '$exeDir/data/flutter_assets/lib/modules';
    }

    // Check for Cython compiled file
    bool hasPyd = false;
    final dir = Directory(modulesDir);
    if (dir.existsSync()) {
      try {
        for (final entity in dir.listSync()) {
          if (entity is File) {
            final name = entity.path.split(Platform.pathSeparator).last;
            if (name.startsWith('document_processor') && name.endsWith('.pyd')) {
              hasPyd = true;
              break;
            }
          }
        }
      } catch (_) {}
    }

    final pythonExe = _getPythonExecutable();
    final pythonArgs = _getPythonArguments(
      modulesDir: modulesDir,
      hasPyd: hasPyd,
      additionalArgs: ['--input', filePath, '--src', 'stats', '--tgt', 'stats'],
    );
    
    try {
      final result = await Process.run(pythonExe, pythonArgs);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.trim().startsWith('{') && line.trim().endsWith('}')) {
            final data = jsonDecode(line.trim()) as Map<String, dynamic>;
            if (data.containsKey('char_count')) {
              return DocumentFileStats(
                charCount: data['char_count'] as int,
                wordCount: data['word_count'] as int,
              );
            }
          }
        }
      }
    } catch (_) {}
    
    return DocumentFileStats(charCount: 0, wordCount: 0);
  }


  /// Splits text into paragraphs and aggregates them into chunks not exceeding maxCharacters
  static List<String> _splitIntoChunks(String text, int maxCharacters) {
    final List<String> chunks = [];
    final paragraphs = text.split('\n');
    final currentChunk = StringBuffer();

    for (final paragraph in paragraphs) {
      if (currentChunk.length + paragraph.length + 1 > maxCharacters) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString());
          currentChunk.clear();
        }
        
        if (paragraph.length > maxCharacters) {
          var remaining = paragraph;
          while (remaining.length > maxCharacters) {
            chunks.add(remaining.substring(0, maxCharacters));
            remaining = remaining.substring(maxCharacters);
          }
          currentChunk.write(remaining);
        } else {
          currentChunk.write(paragraph);
        }
      } else {
        if (currentChunk.isNotEmpty) {
          currentChunk.write('\n');
        }
        currentChunk.write(paragraph);
      }
    }
    
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString());
    }
    
    return chunks;
  }

  /// Translate document at filePath from sourceLang to targetLang.
  /// Yields translation progress updates.
  static Stream<DocumentTranslationProgress> translateDocument({
    required String filePath,
    required String sourceLang,
    required String targetLang,
    int maxChunkCharacters = 4500,
  }) async* {
    final ext = filePath.split('.').last.toLowerCase();
    
    if (ext == 'pdf' || ext == 'xlsx' || ext == 'pptx' || ext == 'docx') {
      yield* _translateViaPython(
        filePath: filePath,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );
      return;
    }

    yield DocumentTranslationProgress(
      currentChunk: 0,
      totalChunks: 0,
      percentage: 0.0,
      status: 'reading_file',
    );

    String originalText = '';
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $filePath');
      }

      if (ext == 'txt' || ext == 'md') {
        originalText = file.readAsStringSync(encoding: utf8);
      } else {
        throw Exception('Unsupported file type: .$ext. Only .txt, .md, .docx, .xlsx, .pptx, and .pdf are supported.');
      }
    } catch (e) {
      yield DocumentTranslationProgress(
        currentChunk: 0,
        totalChunks: 0,
        percentage: 0.0,
        status: 'error_reading_file',
        error: e.toString(),
      );
      return;
    }

    if (originalText.trim().isEmpty) {
      yield DocumentTranslationProgress(
        currentChunk: 0,
        totalChunks: 0,
        percentage: 0.0,
        status: 'error_empty_file',
        error: 'Document text content is empty.',
      );
      return;
    }

    // Split text into chunks
    final chunks = _splitIntoChunks(originalText, maxChunkCharacters);
    final total = chunks.length;
    final translatedBuffer = StringBuffer();

    for (var i = 0; i < total; i++) {
      yield DocumentTranslationProgress(
        currentChunk: i + 1,
        totalChunks: total,
        percentage: i / total,
        status: 'translating_chunk',
      );

      final chunkText = chunks[i];
      final responseStream = ApiClient.translateStream(
        text: chunkText,
        sourceLang: sourceLang,
        targetLang: targetLang,
        imagePaths: [],
      );

      final chunkBuffer = StringBuffer();
      try {
        await for (final token in responseStream) {
          if (token.startsWith('Error:')) {
            throw Exception(token);
          }
          chunkBuffer.write(token);
        }
      } catch (e) {
        yield DocumentTranslationProgress(
          currentChunk: i + 1,
          totalChunks: total,
          percentage: i / total,
          status: 'error_api',
          error: e.toString(),
        );
        return;
      }

      if (translatedBuffer.isNotEmpty) {
        translatedBuffer.write('\n');
      }
      translatedBuffer.write(chunkBuffer.toString());
    }

    yield DocumentTranslationProgress(
      currentChunk: total,
      totalChunks: total,
      percentage: 1.0,
      status: 'complete',
      resultText: translatedBuffer.toString(),
    );
  }

  static Stream<DocumentTranslationProgress> _translateViaPython({
    required String filePath,
    required String sourceLang,
    required String targetLang,
  }) async* {
    final tempDir = Directory.systemTemp.createTempSync('ja_translate_doc');
    final ext = filePath.split('.').last.toLowerCase();
    final tempOutputPath = '${tempDir.path}/translated_output.$ext';

    // Resolve modules directory
    String modulesDir = 'lib/modules';
    if (!Directory(modulesDir).existsSync()) {
      modulesDir = 'data/flutter_assets/lib/modules';
    }
    if (!Directory(modulesDir).existsSync()) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      modulesDir = '$exeDir/data/flutter_assets/lib/modules';
    }

    // Check for Cython compiled file
    bool hasPyd = false;
    final dir = Directory(modulesDir);
    if (dir.existsSync()) {
      try {
        for (final entity in dir.listSync()) {
          if (entity is File) {
            final name = entity.path.split(Platform.pathSeparator).last;
            if (name.startsWith('document_processor') && name.endsWith('.pyd')) {
              hasPyd = true;
              break;
            }
          }
        }
      } catch (_) {}
    }

    final pythonExe = _getPythonExecutable();
    final cacheFile = TranslationCache.cachePath ?? '';
    final pythonArgs = _getPythonArguments(
      modulesDir: modulesDir,
      hasPyd: hasPyd,
      additionalArgs: [
        '--input', filePath,
        '--output', tempOutputPath,
        '--src', sourceLang,
        '--tgt', targetLang,
        if (cacheFile.isNotEmpty) ...['--cache', cacheFile],
      ],
    );

    try {
      final process = await Process.start(pythonExe, pythonArgs);

      final progressController = StreamController<DocumentTranslationProgress>();
      bool hasEmittedError = false;

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        try {
          final data = jsonDecode(line) as Map<String, dynamic>;
          final status = data['status'] as String;
          
          if (status == 'complete') {
            progressController.add(DocumentTranslationProgress(
              currentChunk: 100,
              totalChunks: 100,
              percentage: 1.0,
              status: 'complete',
              resultText: tempOutputPath,
            ));
          } else if (status == 'error') {
            hasEmittedError = true;
            progressController.add(DocumentTranslationProgress(
              currentChunk: 0,
              totalChunks: 0,
              percentage: 0.0,
              status: 'error_api',
              error: data['error'] as String?,
            ));
          } else {
            final progressVal = (data['progress'] as num?)?.toDouble() ?? 0.0;
            progressController.add(DocumentTranslationProgress(
              currentChunk: (progressVal * 100).toInt(),
              totalChunks: 100,
              percentage: progressVal,
              status: status,
            ));
          }
        } catch (_) {
          if (line.trim().isNotEmpty) {
            progressController.add(DocumentTranslationProgress(
              currentChunk: 0,
              totalChunks: 100,
              percentage: 0.05,
              status: line,
            ));
          }
        }
      });

      final errorBuffer = StringBuffer();
      process.stderr.transform(utf8.decoder).listen((data) {
        errorBuffer.write(data);
      });

      process.exitCode.then((exitCode) {
        if (exitCode != 0 && !hasEmittedError) {
          final err = errorBuffer.toString();
          progressController.add(DocumentTranslationProgress(
            currentChunk: 0,
            totalChunks: 0,
            percentage: 0.0,
            status: 'error',
            error: err.isNotEmpty ? err : 'Python script exited with code $exitCode',
          ));
        }
        progressController.close();
      });

      yield* progressController.stream;
    } catch (e) {
      yield DocumentTranslationProgress(
        currentChunk: 0,
        totalChunks: 0,
        percentage: 0.0,
        status: 'error',
        error: 'Failed to start Python process: $e. Please verify Python is installed and in your PATH.',
      );
    }
  }

  static String _getPythonExecutable() {
    // 1. Look for bundled python inside 'data/python/python.exe' (relative to exe)
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final bundledPath = '$exeDir/data/python/python.exe';
    if (File(bundledPath).existsSync()) {
      return bundledPath;
    }
    
    // 2. Look for bundled python inside 'python/python.exe' in project root (for dev/testing)
    final devBundledPath = 'python/python.exe';
    if (File(devBundledPath).existsSync()) {
      return devBundledPath;
    }
    
    // 3. Fallback to system python
    return 'python';
  }

  static List<String> _getPythonArguments({
    required String modulesDir,
    required bool hasPyd,
    required List<String> additionalArgs,
  }) {
    if (hasPyd) {
      // Clean path slashes for python import sys.path
      final cleanPath = modulesDir.replaceAll('\\', '/');
      return [
        '-c',
        "import sys; sys.path.append('$cleanPath'); import document_processor; document_processor.main()",
        ...additionalArgs,
      ];
    } else {
      final scriptPath = '$modulesDir/document_processor.py';
      return [
        scriptPath,
        ...additionalArgs,
      ];
    }
  }
}
