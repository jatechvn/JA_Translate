import 'package:flutter/foundation.dart';
import 'llama_service.dart';

typedef ModelDownload = Stream<Map<String, dynamic>> Function({
  required String downloadUrl,
  required String fileName,
});

/// App-owned transfer; views only subscribe to its current state.
class ModelDownloadController extends ChangeNotifier {
  ModelDownloadController(
      {ModelDownload? download, Future<void> Function()? onCompleted})
      : _download = download ?? LlamaService.downloadModelStream,
        _onCompleted = onCompleted ?? LlamaService.reconcileLocalConfiguration;
  static final instance = ModelDownloadController();
  final ModelDownload _download;
  final Future<void> Function() _onCompleted;
  String? fileName;
  String? error;
  String? completedFile;
  int receivedBytes = 0;
  int totalBytes = 0;
  double bytesPerSecond = 0;
  bool get isDownloading => fileName != null;
  double? get progress => totalBytes > 0
      ? (receivedBytes / totalBytes).clamp(0, 1).toDouble()
      : null;

  Future<void> start(LlamaModelPreset preset) async {
    if (isDownloading) return;
    fileName = preset.fileName;
    error = null;
    completedFile = null;
    receivedBytes = 0;
    totalBytes = 0;
    bytesPerSecond = 0;
    notifyListeners();
    final clock = Stopwatch()..start();
    var previousMicros = 0;
    var previousBytes = 0;
    try {
      await for (final event in _download(
          downloadUrl: preset.downloadUrl, fileName: preset.fileName)) {
        receivedBytes = (event['completed'] as num?)?.toInt() ?? receivedBytes;
        totalBytes = (event['total'] as num?)?.toInt() ?? totalBytes;
        final elapsed = clock.elapsedMicroseconds;
        if (elapsed > previousMicros) {
          bytesPerSecond = (receivedBytes - previousBytes) *
              1000000 /
              (elapsed - previousMicros);
          previousMicros = elapsed;
          previousBytes = receivedBytes;
        }
        if (event['status'] == 'error') throw Exception(event['error']);
        if (event['status'] == 'success') {
          completedFile = preset.fileName;
          await _onCompleted();
        }
        notifyListeners();
      }
      if (completedFile == null) {
        throw StateError('Download ended before completion');
      }
    } catch (e) {
      error = e.toString();
    } finally {
      clock.stop();
      fileName = null;
      notifyListeners();
    }
  }

  static String formatBytes(num bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    return '${bytes.toStringAsFixed(0)} B';
  }
}
