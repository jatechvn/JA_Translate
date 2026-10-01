import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:ja_translate/modules/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/modules/app_config.dart';
import 'package:ja_translate/modules/gguf_translation_service.dart';
import 'package:ja_translate/modules/local_translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Compare the same context passages through two app native workers',
      () async {
    final cases = [
      {
        'id': 'invoice_charge',
        'source': 'en',
        'target': 'vi',
        'text':
            'This is an invoice dispute, not a battery test. The customer says the charge is too high. We agreed to waive it, but the original invoice must remain in the audit log.'
      },
      {
        'id': 'manufacturing_hold',
        'source': 'en',
        'target': 'vi',
        'text':
            'The drive passed the read test, but it failed the write test. We should hold this lot, not scrap it. Here, hold means keeping the lot out of shipment while engineering investigates; it does not mean permanently rejecting it.'
      },
      {
        'id': 'cold_boot_reference',
        'source': 'en',
        'target': 'vi',
        'text':
            'The board failed the cold boot test after a power cycle. A warm restart worked, so the technician replaced the power supply. After that, the board passed the same test. Do not ship it until the final inspection is complete.'
      },
      {
        'id': 'vi_document_integrity',
        'source': 'vi',
        'target': 'en',
        'text':
            'Giữ lại lô hàng SN-2048 để kỹ sư kiểm tra lỗi ghi dữ liệu. Ổ đĩa vẫn đọc được nên chưa được kết luận là hỏng hoàn toàn. Không xóa bản ghi gốc; chỉ tạo một bản dịch để đối chiếu. Hạn xử lý là 15:30, không phải 13:30.'
      },
    ];
    final report = <String, dynamic>{
      'date': '2026-10-01',
      'model': AppConfig.localGgufModel,
      'threads': 4,
      'ggufContext': 4096,
      'sampling': 'greedy',
      'comparison':
          'Same text; OPUS app sentence segmentation vs GGUF entire passage',
      'memory':
          'Sampled currentRss of whole Flutter test process, not isolated model RAM or measured peak',
      'engines': <String, dynamic>{},
      'cases': cases
    };
    await AppConfig.set('LOCAL_AI', 'threads', '4');
    for (final backend in ['opus_mt', 'gguf_native']) {
      final before = ProcessInfo.currentRss;
      final loading = Stopwatch()..start();
      if (backend == 'opus_mt') {
        await LocalTranslationService.instance.load('en-vi');
      } else {
        await GgufTranslationService.instance.load();
      }
      loading.stop();
      final results = <Map<String, dynamic>>[];
      final loadedRss = ProcessInfo.currentRss;
      for (final sample in cases) {
        final watch = Stopwatch()..start();
        final stream = backend == 'opus_mt'
            ? LocalTranslationService.instance.translate(
                text: sample['text']!,
                sourceLang: sample['source']!,
                targetLang: sample['target']!)
            : GgufTranslationService.instance.translate(
                text: sample['text']!,
                sourceLang: sample['source']!,
                targetLang: sample['target']!);
        final text = await stream.join();
        watch.stop();
        expect(text.trim(), isNotEmpty);
        results.add({
          'id': sample['id'],
          'text': text,
          'milliseconds': watch.elapsedMilliseconds,
          'processRssBytes': ProcessInfo.currentRss
        });
      }
      if (backend == 'opus_mt') {
        await LocalTranslationService.instance.unload();
      } else {
        await GgufTranslationService.instance.unload();
      }
      (report['engines'] as Map<String, dynamic>)[backend] = {
        'loadMilliseconds': loading.elapsedMilliseconds,
        'beforeRssBytes': before,
        'loadedRssBytes': loadedRss,
        'afterUnloadRssBytes': ProcessInfo.currentRss,
        'results': results
      };
      // Preserve partial report if the next engine fails.
      File('docs/GGUF_OPUS_COMPARISON.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(report));
    }
    final project = Directory.current.path;
    final selectedModel = GgufTranslationService.modelPath;
    final cacheFixture = Directory(
        '.local_ai_tools/gguf-api-${DateTime.now().microsecondsSinceEpoch}')
      ..createSync(recursive: true);
    await AppConfig.set('LOCAL_AI', 'gguf_model', selectedModel);
    await AppConfig.set('LOCAL_AI', 'engine', 'gguf_native');
    await AppConfig.setActiveProvider('local');
    Directory.current = cacheFixture.absolute.path;
    try {
      final output = await ApiClient.translateStream(
          text: 'Please check the network connection.',
          sourceLang: 'en',
          targetLang: 'vi',
          imagePaths: []).join();
      expect(output, contains('kiểm tra'));
      final cached = jsonDecode(
          File(p.join(Directory.current.path, 'translation_cache.json'))
              .readAsStringSync()) as Map;
      expect(
          cached[
              'gguf-native:${AppConfig.localGgufModel}:en->vi:Please check the network connection.'],
          output);
      await GgufTranslationService.instance.unload();
    } finally {
      Directory.current = project;
    }
    expect(GgufTranslationService.instance.isLoaded, isFalse);
    await GgufTranslationService.instance.load();
    await GgufTranslationService.instance.unload();
    expect(GgufTranslationService.instance.isLoaded, isFalse);
  },
      skip: !Platform.isWindows ||
          Platform.environment['JA_COMPARE_NATIVE'] != '1',
      timeout: const Timeout(Duration(minutes: 8)));
}
