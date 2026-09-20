// lib/main.dart
// Program entry point for JA Translate
// Transparent blur window with Light/Dark/Auto theme

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'modules/constants.dart';
import 'modules/logger_config.dart';
import 'modules/app_config.dart';
import 'modules/translation_cache.dart';
import 'modules/translation_history.dart';
import 'modules/ui/styles.dart';
import 'modules/ui/main_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging configuration
  setupLogger();

  // Load config.ini settings
  await AppConfig.initialize();

  // Initialize translation cache
  TranslationCache.initialize();

  // Initialize translation history
  TranslationHistory.initialize();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Initialize transparent blur core
  await Window.initialize();

  // Configure window options
  const windowOptions = WindowOptions(
    size: Size(1000, 750),
    minimumSize: Size(960, 540),
    title: '$appName  v$appVersion',
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    try {
      await windowManager.setAlignment(Alignment.center);
    } catch (_) {}
  });

  // Apply acrylic / mica transparent background blur
  if (AppConfig.enableTransparency) {
    try {
      await Window.setEffect(
        effect: WindowEffect.acrylic,
        color: const Color(0x00000000), // fully transparent base
      );
    } catch (_) {
      try {
        await Window.setEffect(
          effect: WindowEffect.mica,
          color: const Color(0x00000000),
        );
      } catch (_) {}
    }
  } else {
    try {
      await Window.setEffect(
        effect: WindowEffect.disabled,
      );
    } catch (_) {}
  }

  // Restore saved theme
  final savedThemeStr =
      AppConfig.get('SETTINGS', 'theme', defaultValue: 'dark');
  final savedThemeMode = AppThemeModeExt.fromCode(savedThemeStr);

  runApp(JaTranslateApp(
    initialThemeMode: savedThemeMode,
  ));
}

class JaTranslateApp extends StatefulWidget {
  final AppThemeMode initialThemeMode;

  const JaTranslateApp({
    super.key,
    required this.initialThemeMode,
  });

  @override
  State<JaTranslateApp> createState() => _JaTranslateAppState();
}

class _JaTranslateAppState extends State<JaTranslateApp> {
  late final ThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _themeNotifier = ThemeNotifier(widget.initialThemeMode, platformBrightness);
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    disposeLogger();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: '$appName  v$appVersion',
          debugShowCheckedModeBanner: false,
          theme: buildThemeData(_themeNotifier.colors),
          home: ThemeReveal(
            themeNotifier: _themeNotifier,
            child: MainWindow(
              themeNotifier: _themeNotifier,
            ),
          ),
        );
      },
    );
  }
}
