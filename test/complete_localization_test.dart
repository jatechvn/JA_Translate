import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/theme/language_provider.dart';

void main() {
  test('Complete application localization keys have valid VI/ENG/CN entries',
      () {
    final language = LanguageProvider(initialLang: 'VI');

    final testKeys = [
      // History
      'history_saved_filter',
      'history_clear_title',
      'history_clear_confirm_msg',
      'history_clear_confirm_btn',
      'history_clear_cancel_btn',
      'history_clear_success_toast',
      'history_restored_toast',

      // AI Studio Bento & Engine
      'ai_status_active_ram',
      'ai_status_standby',
      'ai_status_primary_engine',
      'ai_set_primary_btn',
      'ai_set_primary_toast',
      'ai_hw_compute_title',
      'ai_hw_compute_desc',
      'ai_res_ram_title',
      'ai_res_ram_occupied',
      'ai_res_ram_idle',
      'ai_context_title',
      'ai_context_hint',
      'ai_cloud_bridge_title',
      'ai_cloud_bridge_desc',
      'ai_cloud_bridge_btn',

      // Document Translation
      'doc_ready',
      'doc_analyzing',
      'doc_ready_sub',
      'doc_file_selected',
      'doc_file_error',
      'doc_translating',
      'doc_complete',
      'doc_error',
      'doc_cancelled',
      'doc_stats_estimate',
      'doc_supported_formats',
      'doc_config_title',
      'doc_cancel_btn',
      'doc_empty',
      'doc_pdf_analyzing',
      'doc_pdf_applying',
      'doc_excel_scanning',
      'doc_slides_scanning',
      'doc_word_scanning',
      'doc_progress_items',
      'doc_progress_cached',
      'doc_progress_all_cached',

      // Text Translation
      'text_mic_permission_needed',
      'text_attach_image',
      'toast_image_pasted',
      'text_image_n',
      'text_char_count',
      'text_swap_languages',

      // Settings & Dropdown
      'settings_auto_translate',
      'settings_pinyin_display',
      'settings_pdf_fonts',
      'settings_target_lang',
      'dropdown_select_item',
      'dropdown_search_items',
      'dropdown_no_match',

      // Shortcuts
      'shortcut_translate_now',
      'shortcut_tab_text',
      'shortcut_tab_doc',
      'shortcut_tab_history',
      'shortcut_tab_studio',
      'shortcut_cmd_palette',
      'shortcut_toggle_theme',
      'shortcut_open_settings',
      'shortcut_screen_snip',

      // About
      'about_author',
      'about_runtime_mode',
      'about_mutex_active',
      'about_os',
      'about_hardware',
      'about_update_engine',
      'about_ota_engine_desc',

      // TopBar
      'topbar_switch_to_cloud',
      'topbar_switch_to_local',
      'topbar_switched_to_local',
      'topbar_switched_to_cloud',
      'topbar_ota_available_tooltip',
    ];

    for (final key in testKeys) {
      for (final locale in AppLanguage.values) {
        language.setLanguage(locale);
        expect(language.hasTranslation(key, locale), isTrue,
            reason: 'Missing actual ${locale.code} entry for $key');
        final translated = language.t(key);
        expect(translated, isNotEmpty,
            reason: 'Key "$key" should have non-empty text for ${locale.code}');
        expect(translated, isNot(key),
            reason:
                'Key "$key" was not found in dictionary for ${locale.code}');
      }
    }
  });

  test('Parametric translation works with placeholders %s and %d', () {
    final language = LanguageProvider(initialLang: 'ENG');
    expect(language.t('text_char_count', [42]), '42 characters');
    expect(language.t('text_image_n', [3]), 'Image 3');

    language.setLanguage(AppLanguage.vi);
    expect(language.t('text_char_count', [42]), '42 ký tự');
    expect(language.t('text_image_n', [3]), 'Ảnh 3');

    language.setLanguage(AppLanguage.cn);
    expect(language.t('text_char_count', [42]), '42 字符');
    expect(language.t('text_image_n', [3]), '图片 3');
  });
}
