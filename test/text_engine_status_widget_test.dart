import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_translate/theme/language_provider.dart';
import 'package:ja_translate/theme/theme_provider.dart';
import 'package:ja_translate/views/text_translation_view.dart';

void main() {
  testWidgets(
      'Unconfigured cloud shows localized status and configuration dialog',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final language = LanguageProvider(initialLang: 'ENG');
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(initialMode: 'dark')),
      ChangeNotifierProvider.value(value: language),
    ], child: const MaterialApp(home: Scaffold(body: TextTranslationView()))));
    await tester.pump();
    expect(find.text('CLOUD CONFIG REQUIRED'), findsOneWidget);
    expect(find.text('READY'), findsNothing);
    language.setLanguage(AppLanguage.cn);
    await tester.pump();
    expect(find.text('需要云端配置'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Hello');
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('需要云端 AI 配置'), findsOneWidget);
    expect(find.text('云端 AI 需要 API Key、模型和有效的 API 地址。'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    language.dispose();
  });
}
