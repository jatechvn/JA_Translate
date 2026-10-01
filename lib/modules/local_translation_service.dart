import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'app_config.dart';
import 'gguf_translation_service.dart';

const opusPairs = ['en-vi', 'vi-en', 'en-zh', 'zh-en'];

/// CPU inference in this application's worker isolate; no server or subprocess.
class LocalTranslationService extends ChangeNotifier {
  static final instance = LocalTranslationService();
  SendPort? _worker;
  Future<void>? _starting;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  int _nextId = 0;
  bool isLoaded = false;
  String? loadedPair;

  static String get runtimeDirectory {
    final exe = p.join(p.dirname(Platform.resolvedExecutable), 'native');
    if (File(p.join(exe, 'ja_translation.dll')).existsSync()) return exe;
    return p.absolute('native', 'runtime');
  }

  static String get modelsDirectory {
    final exe =
        p.join(p.dirname(Platform.resolvedExecutable), 'models', 'opus-mt');
    if (Directory(exe).existsSync()) return exe;
    return p.absolute('models', 'opus-mt');
  }

  static bool get isAvailable =>
      File(p.join(runtimeDirectory, 'ja_translation.dll')).existsSync() &&
      File(p.join(runtimeDirectory, 'ctranslate2.dll')).existsSync();
  static List<String> get installedPairs => opusPairs.where((pair) {
        final dir = p.join(modelsDirectory, pair);
        return [
          'model.bin',
          'config.json',
          'source.spm',
          'target.spm',
          'manifest.json'
        ].every((name) => File(p.join(dir, name)).existsSync());
      }).toList();
  static Future<void> reconcileConfiguration() async {
    // One-time migration: Qwen native replaces the previous OPUS default.
    if (AppConfig.get('LOCAL_AI', 'qwen_native_migration') != '1') {
      await AppConfig.set('LOCAL_AI', 'engine', 'gguf_native');
      await AppConfig.set('LOCAL_AI', 'qwen_native_migration', '1');
    }
    if (AppConfig.localEngine == 'gguf_native' &&
        GgufTranslationService.isAvailable &&
        File(GgufTranslationService.modelPath).existsSync() &&
        !AppConfig.isLocalAi &&
        AppConfig.get('NVIDIA', 'api_key').trim().isEmpty) {
      await AppConfig.setActiveProvider('local');
    }
  }

  static String normalizeLanguage(String code) => switch (code.toLowerCase()) {
        'vn' || 'vi' => 'vi',
        'eng' || 'en' => 'en',
        'cn' || 'zh' => 'zh',
        _ => 'auto',
      };
  static String detectSource(String text) {
    if (RegExp(r'[\u3400-\u9fff]').hasMatch(text)) return 'zh';
    if (RegExp(r'[ăâđêôơưĂÂĐÊÔƠƯ\u1ea0-\u1ef9]').hasMatch(text)) return 'vi';
    return 'en';
  }

  static List<String> route(String source, String target) {
    if (source == target) return [];
    if (source == 'vi' && target == 'zh') return ['vi-en', 'en-zh'];
    if (source == 'zh' && target == 'vi') return ['zh-en', 'en-vi'];
    final pair = '$source-$target';
    if (!opusPairs.contains(pair)) {
      throw ArgumentError('Unsupported language pair: $pair');
    }
    return [pair];
  }

  Future<void> _startWorker() => _starting ??= () async {
        final receive = ReceivePort();
        final ready = Completer<void>();
        receive.listen((message) {
          if (message is SendPort) {
            _worker = message;
            ready.complete();
          } else if (message is Map) {
            final data = Map<String, dynamic>.from(message);
            _pending.remove(data['id'])?.complete(data);
          }
        });
        await Isolate.spawn(
            _translationWorker, [receive.sendPort, runtimeDirectory]);
        await ready.future;
      }();
  Future<String> _request(String command, String pair, String text) async {
    await _startWorker();
    final id = _nextId++;
    final result = Completer<Map<String, dynamic>>();
    _pending[id] = result;
    _worker!.send({
      'id': id,
      'command': command,
      'pair': pair,
      'modelPath': p.join(modelsDirectory, pair),
      'text': text,
      'threads': AppConfig.localThreads
    });
    final data = await result.future;
    loadedPair = data['loadedPair'] as String?;
    isLoaded = loadedPair != null;
    if (data['error'] != null) {
      notifyListeners();
      throw StateError(data['error'] as String);
    }
    notifyListeners();
    return data['text'] as String? ?? '';
  }

  Future<void> load(String pair) async {
    if (!installedPairs.contains(pair)) {
      throw StateError('Translation pack missing: $pair');
    }
    await _request('load', pair, '');
  }

  Future<void> unload() async {
    if (_worker != null) await _request('unload', loadedPair ?? '', '');
  }

  Stream<String> translate(
      {required String text,
      required String sourceLang,
      required String targetLang}) async* {
    final source = normalizeLanguage(sourceLang);
    final target = normalizeLanguage(targetLang);
    final pairs = route(source == 'auto' ? detectSource(text) : source, target);
    for (final pair in pairs) {
      if (!installedPairs.contains(pair)) {
        throw StateError('Translation pack missing: $pair');
      }
    }
    final parts = text.split(RegExp(r'(\r?\n)'));
    for (var i = 0; i < parts.length; i++) {
      var output = parts[i];
      if (output.trim().isNotEmpty) {
        for (final pair in pairs) {
          output = await _request('translate', pair, output);
        }
      }
      yield output;
      if (i < parts.length - 1) yield '\n';
    }
  }
}

class _NativeEngine {
  _NativeEngine(String runtime) {
    // Open the dependency first with an absolute path for Windows DLL resolution.
    DynamicLibrary.open(p.join(runtime, 'ctranslate2.dll'));
    final lib = DynamicLibrary.open(p.join(runtime, 'ja_translation.dll'));
    allocate = lib.lookupFunction<Pointer<Void> Function(Size),
        Pointer<Void> Function(int)>('ja_alloc');
    free = lib.lookupFunction<Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('ja_free');
    load = lib.lookupFunction<Pointer<Void> Function(Pointer<Uint8>, Int32),
        Pointer<Void> Function(Pointer<Uint8>, int)>('ja_load');
    unload = lib.lookupFunction<Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('ja_unload');
    count = lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Uint8>),
        int Function(Pointer<Void>, Pointer<Uint8>)>('ja_token_count');
    translate = lib.lookupFunction<
        Pointer<Uint8> Function(Pointer<Void>, Pointer<Uint8>, Pointer<Uint8>),
        Pointer<Uint8> Function(
            Pointer<Void>, Pointer<Uint8>, Pointer<Uint8>)>('ja_translate');
    lastError = lib.lookupFunction<Pointer<Uint8> Function(),
        Pointer<Uint8> Function()>('ja_last_error');
  }
  late final Pointer<Void> Function(int) allocate;
  late final void Function(Pointer<Void>) free;
  late final Pointer<Void> Function(Pointer<Uint8>, int) load;
  late final void Function(Pointer<Void>) unload;
  late final int Function(Pointer<Void>, Pointer<Uint8>) count;
  late final Pointer<Uint8> Function(
      Pointer<Void>, Pointer<Uint8>, Pointer<Uint8>) translate;
  late final Pointer<Uint8> Function() lastError;
  Pointer<Uint8> string(String text) {
    final bytes = utf8.encode(text);
    final ptr = allocate(bytes.length + 1).cast<Uint8>();
    if (ptr == nullptr) throw StateError('Native allocation failed');
    ptr.asTypedList(bytes.length + 1).setAll(0, [...bytes, 0]);
    return ptr;
  }

  String read(Pointer<Uint8> ptr) {
    var length = 0;
    while (length < 8 * 1024 * 1024 && ptr[length] != 0) {
      length++;
    }
    if (length == 8 * 1024 * 1024) {
      throw StateError('Native string exceeds limit');
    }
    return utf8.decode(ptr.asTypedList(length));
  }

  String translateChunk(Pointer<Void> handle, String text, String prefix) {
    // Keep sentence contexts short: small Marian models can omit sentences in
    // long/repetitive paragraphs even when the encoder token limit is respected.
    final sentences = text
        .split(RegExp(r'(?<=[.!?。！？])\s+|(?<=[。！？])'))
        .where((sentence) => sentence.trim().isNotEmpty)
        .toList();
    if (sentences.length > 1) {
      return sentences
          .map((sentence) => translateChunk(handle, sentence, prefix))
          .join(' ');
    }
    final input = string(text);
    final tag = string(prefix);
    try {
      final tokens = count(handle, input);
      if (tokens < 0) throw StateError(read(lastError()));
      if (tokens > 240) {
        final chars = text.runes.toList();
        var split = chars.length ~/ 2;
        for (var i = split; i > split ~/ 2; i--) {
          if (RegExp(r'\s').hasMatch(String.fromCharCode(chars[i]))) {
            split = i;
            break;
          }
        }
        return '${translateChunk(handle, String.fromCharCodes(chars.take(split)), prefix)} '
            '${translateChunk(handle, String.fromCharCodes(chars.skip(split)), prefix)}';
      }
      final output = translate(handle, input, tag);
      if (output == nullptr) throw StateError(read(lastError()));
      try {
        return read(output);
      } finally {
        free(output.cast<Void>());
      }
    } finally {
      free(input.cast<Void>());
      free(tag.cast<Void>());
    }
  }
}

void _translationWorker(List<dynamic> args) {
  final reply = args[0] as SendPort;
  final port = ReceivePort();
  _NativeEngine? engine;
  Pointer<Void> handle = nullptr;
  String? currentPair;
  reply.send(port.sendPort);
  port.listen((message) {
    final data = message as Map;
    try {
      engine ??= _NativeEngine(args[1] as String);
      final native = engine!;
      final pair = data['pair'] as String;
      if (data['command'] == 'unload') {
        if (handle != nullptr) native.unload(handle);
        handle = nullptr;
        currentPair = null;
      } else {
        if (currentPair != pair || handle == nullptr) {
          if (handle != nullptr) native.unload(handle);
          handle = nullptr;
          currentPair = null;
          final path = native.string(data['modelPath'] as String);
          try {
            handle = native.load(path, data['threads'] as int);
          } finally {
            native.free(path.cast<Void>());
          }
          if (handle == nullptr) {
            throw StateError(native.read(native.lastError()));
          }
          currentPair = pair;
        }
      }
      final output = data['command'] == 'translate'
          ? native.translateChunk(
              handle,
              data['text'] as String,
              switch (pair) {
                'en-vi' => '>>vie<<',
                'en-zh' => '>>cmn_Hans<<',
                _ => ''
              })
          : '';
      reply.send({'id': data['id'], 'text': output, 'loadedPair': currentPair});
    } catch (error) {
      reply.send({
        'id': data['id'],
        'error': error.toString(),
        'loadedPair': currentPair
      });
    }
  });
}
