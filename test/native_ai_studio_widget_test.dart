import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_translate/modules/app_config.dart';
import 'package:ja_translate/theme/language_provider.dart';
import 'package:ja_translate/theme/theme_provider.dart';
import 'package:ja_translate/views/ai_engine_studio_view.dart';

void main() {
  testWidgets(
      'Embedded AI Studio follows language changes and fits desktop width',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await AppConfig.set('LOCAL_AI', 'engine', 'gguf_native');
    final language = LanguageProvider(initialLang: 'ENG');
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(initialMode: 'dark')),
      ChangeNotifierProvider.value(value: language),
    ], child: const MaterialApp(home: Scaffold(body: AiEngineStudioView()))));
    await tester.pump();
    expect(find.text('Qwen GGUF · CPU'), findsOneWidget);
    expect(find.text(language.tr('ai_gguf_description')), findsOneWidget);
    expect(find.text('Load model'), findsOneWidget);
    language.setLanguage(AppLanguage.cn);
    await tester.pump();
    expect(find.text('加载模型'), findsOneWidget);
    expect(find.text(language.tr('ai_gguf_limit')), findsOneWidget);
    expect(AppConfig.localEngine, 'gguf_native');
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    language.dispose();
  });
}
