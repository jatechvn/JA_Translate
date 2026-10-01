import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/theme/language_provider.dart';

void main() {
  test('AI Studio follows language changes including download feedback', () {
    final language = LanguageProvider(initialLang: 'VI');
    expect(language.tr('ai_studio_24'), 'Tải GGUF');
    language.setLanguage(AppLanguage.en);
    expect(language.tr('ai_studio_24'), 'Download GGUF');
    expect(language.tr('ai_download_error'), 'Model download failed');
    language.setLanguage(AppLanguage.cn);
    expect(language.tr('ai_studio_24'), '下载 GGUF');
    expect(language.tr('ai_download_success'), '模型已下载到 models/！');
  });

  test('All AI Studio labels and model descriptions have VI/ENG/CN entries',
      () {
    final language = LanguageProvider(initialLang: 'VI');
    final keys = [
      for (var i = 0; i < 39; i++) 'ai_studio_$i',
      for (var i = 0; i < 4; i++) ...['ai_preset_name_$i', 'ai_preset_desc_$i'],
      'ai_download_success',
      'ai_download_error',
      'ai_downloading',
      'ai_native_description',
      'ai_native_loaded',
      'ai_native_auto_load',
      'ai_native_load',
      'ai_native_unload',
      'ai_native_folder',
      'ai_native_error',
      'ai_native_pivot',
      'ai_native_engine',
      'ai_engine_opus',
      'ai_engine_gguf',
      'ai_gguf_description',
      'ai_gguf_limit',
      'engine_missing_native',
      'engine_missing_translation_pack',
    ];
    for (final key in keys) {
      for (final locale in AppLanguage.values) {
        language.setLanguage(locale);
        expect(language.tr(key), isNotEmpty, reason: '$key ${locale.code}');
        expect(language.tr(key), isNot(key), reason: '$key ${locale.code}');
      }
    }
  });
}
