import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_translate/theme/language_provider.dart';
import 'package:ja_translate/theme/theme_provider.dart';
import 'package:ja_translate/layout/dashboard_shell.dart';
import 'package:ja_translate/modules/app_config.dart';

void main() {
  test('Document progress localizes worker stages, counts and errors', () {
    final lang = LanguageProvider(initialLang: 'VI');
    const expected = {
      AppLanguage.vi: 'Đang dịch mục 2 / 7…',
      AppLanguage.en: 'Translating item 2 / 7…',
      AppLanguage.cn: '正在翻译第 2 / 7 项…',
    };
    for (final locale in AppLanguage.values) {
      lang.setLanguage(locale);
      expect(lang.documentProgressText('translating_chunk', 2, 7),
          expected[locale]);
      for (final format in [
        'PDF text block',
        'Excel cells',
        'PowerPoint texts',
        'Word text'
      ]) {
        expect(
            lang.documentProgressText('Translating $format 2 of 7...', 20, 100),
            expected[locale]);
      }
      expect(lang.documentProgressText('reading_file', 0, 0),
          lang.t('doc_analyzing'));
      expect(lang.documentProgressText('error_api', 0, 0), lang.t('doc_error'));
      expect(
          lang.documentProgressText('complete', 7, 7), lang.t('doc_complete'));
      expect(
          lang.documentProgressText(
              'Found 3 cached translations. Translating remaining 4 texts...',
              5,
              100),
          lang.t('doc_progress_cached', [3, 4]));
      expect(
          lang.documentProgressText(
              'All 7 texts loaded from local cache!', 5, 100),
          lang.t('doc_progress_all_cached', [7]));
      for (final entry in {
        'Analyzing PDF layout...': 'doc_pdf_analyzing',
        'Applying PDF modifications...': 'doc_pdf_applying',
        'Scanning Excel sheets...': 'doc_excel_scanning',
        'Scanning slides...': 'doc_slides_scanning',
        'Scanning Word paragraphs...': 'doc_word_scanning',
      }.entries) {
        expect(lang.hasTranslation(entry.value, locale), isTrue);
        expect(lang.documentProgressText(entry.key, 0, 0), lang.t(entry.value));
      }
      expect(lang.documentProgressText('unknown worker diagnostic', 0, 0),
          lang.t('doc_translating'));
    }
    lang.dispose();
  });

  testWidgets('TopBar tooltips and both engine toasts follow VI ENG CN',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previous = AppConfig.isLocalAi ? 'local' : 'cloud';
    final lang = LanguageProvider(initialLang: 'VI');
    final theme = ThemeProvider(initialMode: 'dark');
    await AppConfig.setActiveProvider('cloud');
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: lang),
      ChangeNotifierProvider.value(value: theme),
    ], child: const MaterialApp(home: Scaffold(body: DashboardShell()))));
    await tester.pump(const Duration(milliseconds: 300));
    for (final locale in AppLanguage.values) {
      await AppConfig.setActiveProvider('cloud');
      lang.setLanguage(locale);
      await tester.pump();
      final local = find.byTooltip(lang.t('topbar_switch_to_local'));
      expect(local, findsOneWidget);
      await tester.tap(local);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(lang.t('topbar_switched_to_local')), findsOneWidget);
      final cloud = find.byTooltip(lang.t('topbar_switch_to_cloud'));
      expect(cloud, findsOneWidget);
      await tester.tap(cloud);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(lang.t('topbar_switched_to_cloud')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await AppConfig.setActiveProvider(previous);
    lang.dispose();
    theme.dispose();
  });
}
