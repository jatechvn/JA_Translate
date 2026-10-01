import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/modules/model_download_controller.dart';
import 'package:ja_translate/modules/llama_service.dart';

void main() {
  test(
      'Transfer survives detached view, restores progress and rejects duplicate starts',
      () async {
    final events = StreamController<Map<String, dynamic>>();
    var requests = 0;
    final controller = ModelDownloadController(
        onCompleted: () async {},
        download: ({required downloadUrl, required fileName}) {
          requests++;
          return events.stream;
        });
    var notifications = 0;
    void listener() => notifications++;
    controller.addListener(listener);
    final transfer = controller.start(LlamaService.presets.first);
    events.add({'status': 'downloading', 'completed': 1024, 'total': 4096});
    await Future<void>.delayed(const Duration(milliseconds: 10));
    controller.removeListener(listener); // leaving AI Studio
    events.add({'status': 'downloading', 'completed': 2048, 'total': 4096});
    await Future<void>.delayed(const Duration(milliseconds: 10));
    controller.addListener(listener); // returning to AI Studio
    expect(controller.isDownloading, isTrue);
    expect(controller.receivedBytes, 2048);
    expect(controller.totalBytes, 4096);
    expect(controller.progress, 0.5);
    expect(controller.bytesPerSecond, greaterThan(0));
    await controller.start(LlamaService.presets[1]);
    expect(requests, 1);
    events.add({'status': 'success', 'completed': 4096, 'total': 4096});
    await events.close();
    await transfer;
    expect(controller.isDownloading, isFalse);
    expect(controller.completedFile, LlamaService.presets.first.fileName);
    expect(controller.error, isNull);
    expect(notifications, greaterThan(1));
    controller.dispose();
  });

  test('Failure releases transfer lock; unknown size stays indeterminate',
      () async {
    final controller = ModelDownloadController(
        onCompleted: () async {},
        download: ({required downloadUrl, required fileName}) async* {
          yield {'status': 'downloading', 'completed': 123, 'total': 0};
          yield {'status': 'error', 'error': 'HTTP 404'};
        });
    await controller.start(LlamaService.presets.first);
    expect(controller.progress, isNull);
    expect(controller.receivedBytes, 123);
    expect(controller.isDownloading, isFalse);
    expect(controller.completedFile, isNull);
    expect(controller.error, contains('HTTP 404'));
    controller.dispose();
  });
}
