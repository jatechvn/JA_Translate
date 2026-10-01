import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/modules/engine_readiness.dart';
import 'package:ja_translate/theme/language_provider.dart';

void main() {
  String readiness(
          {bool local = false,
          String key = 'key',
          String model = 'model',
          String url = 'https://example.com/v1',
          List<String> installed = const ['model.gguf'],
          bool server = true}) =>
      EngineReadiness.evaluate(
          isLocal: local,
          apiKey: key,
          cloudModel: model,
          apiBase: url,
          localModel: 'model.gguf',
          installedModels: installed,
          hasLocalServer: server);
  test('Readiness checks active engine prerequisites', () {
    expect(readiness(key: ''), 'engine_missing_cloud_config');
    expect(readiness(model: ''), 'engine_missing_cloud_config');
    expect(readiness(url: 'invalid'), 'engine_missing_cloud_config');
    expect(readiness(), 'engine_configured');
    expect(readiness(local: true, installed: []), 'engine_missing_local_model');
    expect(
        readiness(local: true, server: false), 'engine_missing_local_server');
    expect(readiness(local: true, key: ''), 'engine_configured');
  });
  test('Configuration dialogs and statuses follow VI/ENG/CN', () {
    final lang = LanguageProvider(initialLang: 'VI');
    for (final key in [
      'engine_missing_local_model',
      'engine_missing_local_server',
      'engine_missing_cloud_config',
      'engine_configured',
      'ai_unknown_size',
      'missing_local_title',
      'missing_local_body',
      'missing_local_hint',
      'missing_cloud_title',
      'missing_cloud_body',
      'missing_cloud_hint',
      'missing_local_server_title',
      'missing_local_server_body',
      'use_cloud_temporarily'
    ]) {
      lang.setLanguage(AppLanguage.vi);
      final vi = lang.tr(key);
      for (final locale in [AppLanguage.en, AppLanguage.cn]) {
        lang.setLanguage(locale);
        expect(lang.tr(key), isNot(key));
        expect(lang.tr(key), isNot(vi));
      }
    }
  });
}
