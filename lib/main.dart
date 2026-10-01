import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme_provider.dart';
import 'theme/language_provider.dart';
import 'layout/dashboard_shell.dart';
import 'widgets/command_palette.dart';
import 'widgets/app_toast.dart';
import 'modules/constants.dart';
import 'modules/logger_config.dart';
import 'modules/app_config.dart';
import 'modules/llama_service.dart';
import 'modules/local_translation_service.dart';
import 'modules/translation_cache.dart';
import 'modules/translation_history.dart';
import 'modules/desktop_service.dart';
import 'modules/window_helper.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup diagnostic logger
  setupLogger();

  // Load config.ini
  await AppConfig.initialize();
  await LocalTranslationService.reconcileConfiguration();
  if (!['opus_mt', 'gguf_native'].contains(AppConfig.localEngine)) {
    await LlamaService.reconcileLocalConfiguration();
  }

  // Initialize translation cache & history
  TranslationCache.initialize();
  TranslationHistory.initialize();

  // Initialize Windows desktop glass window
  await initGlassWindow(
    title: '$appName  v$appVersion',
    size: const Size(1200, 820),
    minSize: const Size(800, 560),
  );

  // Initialize desktop system tray and global hotkeys
  DesktopService().initialize(
    onQuickTranslate: () {},
    onScreenSnip: () {},
  );

  runApp(const JaTranslateApp());
}

class JaTranslateApp extends StatelessWidget {
  const JaTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colors = theme.colors;
    final effectiveTitle = (!kIsWeb && Platform.isWindows && !theme.isWin11)
        ? ''
        : '$appName  v$appVersion';

    return MaterialApp(
      title: effectiveTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: Builder(
        builder: (ctx) {
          return CommandPaletteShortcut(
            items: () => [
              CommandPaletteItem(
                label: 'Chuyển Theme Sáng / Tối',
                subtitle: 'Đổi chế độ giao diện 1-Click (Shift+L)',
                icon: Icons.brightness_4_rounded,
                onSelect: () => theme.toggleTheme(),
              ),
              CommandPaletteItem(
                label: 'Khôi phục Glass Tuning',
                subtitle: 'Đặt lại Blur và Opacity về chuẩn mặc định',
                icon: Icons.refresh_rounded,
                onSelect: () {
                  theme.resetToDefaults();
                  showAppToast(
                    ctx,
                    colors: colors,
                    message: 'Đã khôi phục Glass Tuning chuẩn Bento!',
                    icon: Icons.check_circle_rounded,
                    accentColor: colors.accentCyan,
                  );
                },
              ),
              CommandPaletteItem(
                label: 'Xóa bộ nhớ đệm dịch thuật',
                subtitle: 'Giải phóng RAM và làm mới Translation Cache',
                icon: Icons.cleaning_services_rounded,
                onSelect: () {
                  TranslationCache.clear();
                  showAppToast(
                    ctx,
                    colors: colors,
                    message: 'Đã xóa bộ nhớ đệm dịch thuật!',
                    icon: Icons.check_circle_rounded,
                    accentColor: colors.accentEmerald,
                  );
                },
              ),
            ],
            child: const DashboardShell(
              appTitle: appName,
              appVersion: appVersion,
            ),
          );
        },
      ),
    );
  }
}
