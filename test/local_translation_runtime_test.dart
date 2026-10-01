import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/modules/app_config.dart';
import 'package:ja_translate/modules/local_translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Language routing preserves direct pairs and uses English for VI to ZH',
      () {
    expect(LocalTranslationService.route('vi', 'zh'), ['vi-en', 'en-zh']);
    expect(LocalTranslationService.route('en', 'vi'), ['en-vi']);
    expect(LocalTranslationService.route('zh', 'vi'), ['zh-en', 'en-vi']);
    expect(LocalTranslationService.route('vi', 'vi'), isEmpty);
    expect(LocalTranslationService.detectSource('Kiểm tra kết nối'), 'vi');
    expect(LocalTranslationService.detectSource('检查网络连接'), 'zh');
  });
  test('Native DLL translates, changes model and reloads in app worker',
      () async {
    await AppConfig.set('LOCAL_AI', 'engine', 'opus_mt');
    await AppConfig.set('LOCAL_AI', 'threads', '4');
    final engine = LocalTranslationService.instance;
    for (final request in [
      ('en', 'vi', 'Please check the network connection.'),
      ('vi', 'en', 'Vui lòng kiểm tra kết nối mạng.'),
      ('en', 'zh', 'Please check the network connection.'),
      ('zh', 'en', '请检查网络连接。'),
      ('zh', 'vi', '请检查网络连接。'),
      ('vi', 'zh', 'Vui lòng kiểm tra kết nối mạng.'),
    ]) {
      final result = await engine
          .translate(
              text: request.$3, sourceLang: request.$1, targetLang: request.$2)
          .join();
      expect(result.trim(), isNotEmpty);
      expect(result.length, lessThan(250),
          reason: 'Short input must not repeat until decoder limit');
      expect(result, isNot(request.$3));
      // Real output helps reviewers assess these small models' limitations.
      debugPrint('${request.$1}->${request.$2}: $result');
    }
    final longInput =
        '${List.filled(50, 'Please check the network connection.').join(' ')} The final number is 987654321.';
    final longOutput = await engine
        .translate(text: longInput, sourceLang: 'en', targetLang: 'vi')
        .join();
    expect(longOutput, contains('987654321'),
        reason: 'Splitting must preserve the tail of long input');
    await engine.unload();
    expect(engine.isLoaded, isFalse);
    final result = await engine
        .translate(
            text: 'Hello.\nPlease check the cable.',
            sourceLang: 'en',
            targetLang: 'vi')
        .join();
    expect(result.split('\n'), hasLength(2));
    await engine.unload();
  },
      skip:
          !Platform.isWindows || Platform.environment['JA_TEST_NATIVE'] != '1',
      timeout: const Timeout(Duration(minutes: 3)));
}
