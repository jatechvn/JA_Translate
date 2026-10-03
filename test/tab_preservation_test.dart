import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_translate/theme/language_provider.dart';
import 'package:ja_translate/theme/theme_provider.dart';
import 'package:ja_translate/layout/dashboard_shell.dart';
import 'package:ja_translate/modules/power_coordinator.dart';

void main() {
  testWidgets(
      'Switching tabs preserves input text and view state without clearing',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(PowerCoordinator.instance.cancelIdleTimer);

    final language = LanguageProvider(initialLang: 'ENG');
    final theme = ThemeProvider(initialMode: 'dark');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: language),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardShell(),
          ),
        ),
      ),
    );
    await tester.pump();

    // 1. Enter text in the TextTranslationView (Tab 0)
    final inputField = find.byType(TextField).first;
    const testText = 'Hello Antigravity Text Preservation Test';
    await tester.enterText(inputField, testText);
    await tester.pump();

    expect(find.text(testText), findsOneWidget);

    // 2. Switch to Tab 1 (Documents)
    final documentTab = find.byTooltip('Documents');
    expect(documentTab, findsOneWidget);
    await tester.ensureVisible(documentTab);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(documentTab);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify text is kept alive offstage
    expect(find.text(testText, skipOffstage: false), findsOneWidget);

    // 3. Switch to Tab 3 (AI Studio)
    final aiStudioTab = find.byTooltip('AI Studio');
    expect(aiStudioTab, findsOneWidget);
    await tester.ensureVisible(aiStudioTab);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(aiStudioTab, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    // Still kept alive in tree offstage
    expect(find.text(testText, skipOffstage: false), findsOneWidget);

    // 4. Switch back to Tab 0 (Text Translation)
    final textTab = find.byTooltip('Text');
    expect(textTab, findsOneWidget);
    await tester.ensureVisible(textTab);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(textTab);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    // 5. Verify the input text is STILL THERE and active onstage!
    expect(find.text(testText), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    PowerCoordinator.instance.cancelIdleTimer();
    language.dispose();
    theme.dispose();
  });
}
