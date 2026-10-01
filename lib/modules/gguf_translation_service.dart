import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'app_config.dart';
import 'llama_service.dart';

/// GGUF inference in the app process, independent of views and HTTP services.
class GgufTranslationService extends ChangeNotifier {
  static final instance = GgufTranslationService();
  SendPort? _worker;
  Future<void>? _starting;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  int _nextId = 0;
  bool isLoaded = false;
  static String get runtimeDirectory {
    final shipped =
        p.join(p.dirname(Platform.resolvedExecutable), 'native', 'gguf');
    if (File(p.join(shipped, 'ja_gguf.dll')).existsSync()) return shipped;
    return p.absolute('native', 'runtime', 'gguf');
  }

  static bool get isAvailable => [
        'ja_gguf.dll',
        'llama.dll',
        'ggml.dll',
        'ggml-base.dll',
        'ggml-cpu-x64.dll',
        'libomp.dll'
      ].every((file) => File(p.join(runtimeDirectory, file)).existsSync());
  static String get modelPath =>
      p.join(LlamaService.getModelsDirectory(), AppConfig.localGgufModel);

  Future<void> _start() => _starting ??= () async {
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
        await Isolate.spawn(_ggufWorker, [receive.sendPort, runtimeDirectory]);
        await ready.future;
      }();
  Future<String> _request(String command,
      {String text = '', String source = 'auto', String target = 'vi'}) async {
    await _start();
    final id = _nextId++;
    final result = Completer<Map<String, dynamic>>();
    _pending[id] = result;
    _worker!.send({
      'id': id,
      'command': command,
      'text': text,
      'source': source,
      'target': target,
      'model': modelPath,
      'threads': AppConfig.localThreads
    });
    final response = await result.future;
    isLoaded = response['loaded'] == true;
    notifyListeners();
    if (response['error'] != null) {
      throw StateError(response['error'] as String);
    }
    return response['text'] as String? ?? '';
  }

  Future<void> load() async {
    await _request('load');
  }

  Future<void> unload() async {
    if (_worker != null) await _request('unload');
  }

  Stream<String> translate(
      {required String text,
      required String sourceLang,
      required String targetLang}) async* {
    if (text.trim().isEmpty) return;
    // Keep the whole passage together so pronouns and terminology share context.
    yield await _request('translate',
        text: text, source: sourceLang, target: targetLang);
  }
}

class _GgufNative {
  _GgufNative(String runtime) {
    for (final name in [
      'libomp.dll',
      'ggml-base.dll',
      'ggml.dll',
      'llama.dll'
    ]) {
      DynamicLibrary.open(p.join(runtime, name));
    }
    final library = DynamicLibrary.open(p.join(runtime, 'ja_gguf.dll'));
    alloc = library.lookupFunction<Pointer<Void> Function(Size),
        Pointer<Void> Function(int)>('ja_g_alloc');
    free = library.lookupFunction<Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('ja_g_free');
    load = library.lookupFunction<
        Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>, Int32),
        Pointer<Void> Function(
            Pointer<Uint8>, Pointer<Uint8>, int)>('ja_g_load');
    unload = library.lookupFunction<Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('ja_g_unload');
    translate = library.lookupFunction<
        Pointer<Uint8> Function(
            Pointer<Void>, Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>),
        Pointer<Uint8> Function(Pointer<Void>, Pointer<Uint8>, Pointer<Uint8>,
            Pointer<Uint8>)>('ja_g_translate');
    error = library.lookupFunction<Pointer<Uint8> Function(),
        Pointer<Uint8> Function()>('ja_g_error');
  }
  late final Pointer<Void> Function(int) alloc;
  late final void Function(Pointer<Void>) free;
  late final Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>, int) load;
  late final void Function(Pointer<Void>) unload;
  late final Pointer<Uint8> Function(
      Pointer<Void>, Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>) translate;
  late final Pointer<Uint8> Function() error;
  Pointer<Uint8> string(String value) {
    final bytes = utf8.encode(value);
    final pointer = alloc(bytes.length + 1).cast<Uint8>();
    if (pointer == nullptr) throw StateError('Native allocation failed');
    pointer.asTypedList(bytes.length + 1).setAll(0, [...bytes, 0]);
    return pointer;
  }

  String read(Pointer<Uint8> pointer) {
    var length = 0;
    while (length < 8 * 1024 * 1024 && pointer[length] != 0) {
      length++;
    }
    if (length == 8 * 1024 * 1024) {
      throw StateError('GGUF output exceeds limit');
    }
    return utf8.decode(pointer.asTypedList(length));
  }
}

void _ggufWorker(List<dynamic> args) {
  final reply = args[0] as SendPort;
  final port = ReceivePort();
  _GgufNative? api;
  Pointer<Void> handle = nullptr;
  String? loadedPath;
  reply.send(port.sendPort);
  port.listen((message) {
    final data = message as Map;
    try {
      api ??= _GgufNative(args[1] as String);
      final native = api!;
      if (data['command'] == 'unload') {
        if (handle != nullptr) native.unload(handle);
        handle = nullptr;
        loadedPath = null;
      } else if (handle == nullptr || loadedPath != data['model']) {
        if (handle != nullptr) native.unload(handle);
        handle = nullptr;
        loadedPath = null;
        final path = native.string(data['model'] as String);
        final runtime = native.string(args[1] as String);
        try {
          handle = native.load(path, runtime, data['threads'] as int);
        } finally {
          native.free(path.cast<Void>());
          native.free(runtime.cast<Void>());
        }
        if (handle == nullptr) throw StateError(native.read(native.error()));
        loadedPath = data['model'] as String;
      }
      var result = '';
      if (data['command'] == 'translate') {
        final input = native.string(data['text'] as String);
        final source = native.string(data['source'] as String);
        final target = native.string(data['target'] as String);
        try {
          final output = native.translate(handle, input, source, target);
          if (output == nullptr) throw StateError(native.read(native.error()));
          try {
            result = native.read(output);
          } finally {
            native.free(output.cast<Void>());
          }
        } finally {
          native.free(input.cast<Void>());
          native.free(source.cast<Void>());
          native.free(target.cast<Void>());
        }
      }
      reply.send(
          {'id': data['id'], 'text': result, 'loaded': handle != nullptr});
    } catch (error) {
      reply.send({
        'id': data['id'],
        'error': error.toString(),
        'loaded': handle != nullptr
      });
    }
  });
}
