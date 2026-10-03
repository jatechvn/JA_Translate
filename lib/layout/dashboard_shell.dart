import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../theme/app_colors.dart';
import '../modules/constants.dart';
import '../modules/app_config.dart';
import '../modules/engine_readiness.dart';
import '../modules/ota_update_service.dart';
import '../modules/llama_service.dart';
import '../modules/power_coordinator.dart';
import '../modules/ui/app_shortcuts.dart';
import '../modules/ui/glass_update_dialog.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/mobile_dock_nav.dart';
import '../widgets/app_toast.dart';
import '../views/text_translation_view.dart';
import '../views/document_translation_view.dart';
import '../views/translation_history_view.dart';
import '../views/ai_engine_studio_view.dart';

part 'dashboard_shell_settings.dart';

class DashboardShell extends StatefulWidget {
  final String appTitle;
  final String appVersion;
  final bool isDebug;
  final String? buildTimestamp;

  const DashboardShell({
    super.key,
    this.appTitle = 'JA Translate',
    this.appVersion = '1.2.0',
    this.isDebug = false,
    this.buildTimestamp,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;
  final GlobalKey<TextTranslationViewState> _textTranslationKey =
      GlobalKey<TextTranslationViewState>();
  bool _hasPendingOtaUpdate = false;
  UpdatePackageInfo? _pendingOtaPackage;
  Timer? _aiStatusTimer;
  bool _isLocalAiRunning = false;

  static const double _mobileBreakpoint = 880;

  static const _tabIcons = [
    Icons.translate_rounded,
    Icons.description_rounded,
    Icons.history_rounded,
    Icons.psychology_rounded,
  ];

  @override
  void initState() {
    super.initState();
    AppConfig.changes.addListener(_onConfigurationChanged);
    PowerCoordinator.instance.addListener(_onPowerStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOtaOnStartup();
      _checkAiStatus();
    });
    _aiStatusTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (PowerCoordinator.instance.isUiActive) {
        _checkAiStatus();
      }
    });
  }

  @override
  void dispose() {
    AppConfig.changes.removeListener(_onConfigurationChanged);
    PowerCoordinator.instance.removeListener(_onPowerStateChanged);
    _aiStatusTimer?.cancel();
    super.dispose();
  }

  void _onPowerStateChanged() {
    if (mounted && PowerCoordinator.instance.isUiActive) {
      _checkAiStatus();
    }
  }

  void _onConfigurationChanged() {
    if (mounted) setState(() {});
  }

  void _checkAiStatus() {
    final running = LlamaService().isRunning;
    if (running != _isLocalAiRunning && mounted) {
      setState(() => _isLocalAiRunning = running);
    }
  }

  Future<void> _toggleAiEngine() async {
    final willBeLocal = !AppConfig.isLocalAi;
    final targetProvider = willBeLocal ? 'local' : 'cloud';
    await AppConfig.setActiveProvider(targetProvider);

    if (!mounted) return;
    final lang = context.read<LanguageProvider>();
    showAppToast(
      context,
      message: lang.t(willBeLocal
          ? 'topbar_switched_to_local'
          : 'topbar_switched_to_cloud'),
      icon: willBeLocal ? Icons.memory_rounded : Icons.cloud_done_rounded,
      accentColor: willBeLocal
          ? context.read<ThemeProvider>().colors.accentEmerald
          : context.read<ThemeProvider>().colors.accentCyan,
    );
  }

  Future<void> _checkOtaOnStartup() async {
    try {
      final service = OtaUpdateService();
      final config = await service.loadConfig();
      if (!service.shouldCheckForUpdates(
        interval: config.checkInterval,
        lastCheckTime: config.lastCheckTime,
      )) {
        return;
      }

      final result = await service.checkForUpdates();
      if (mounted && result.hasUpdate && result.packageInfo != null) {
        setState(() {
          _hasPendingOtaUpdate = true;
          _pendingOtaPackage = result.packageInfo;
        });

        final language = context.read<LanguageProvider>();
        await showGlassUpdateDialog(
          context: context,
          packageInfo: result.packageInfo!,
          uiLang: language.currentLanguage.code,
        );
      }
    } catch (e) {
      debugPrint('[DashboardShell] Startup OTA check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final language = context.watch<LanguageProvider>();
    final colors = theme.colors;
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    return AppShortcuts(
      commands: {
        AppCommand.overview: () => setState(() => _currentIndex = 0),
        AppCommand.components: () => setState(() => _currentIndex = 1),
        AppCommand.terminal: () => setState(() => _currentIndex = 2),
        AppCommand.devices: () => setState(() => _currentIndex = 3),
        AppCommand.settings: () =>
            _showGlassSettingsDialog(context, theme, language),
        AppCommand.theme: theme.toggleTheme,
      },
      child: GlassScaffold(
        colors: colors,
        header: _buildTopHeader(context, theme, language, colors, isMobile),
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, isMobile ? 84 : 14),
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  TextTranslationView(key: _textTranslationKey),
                  const DocumentTranslationView(
                    key: ValueKey('DocumentTranslationView'),
                  ),
                  TranslationHistoryView(
                    key: const ValueKey('TranslationHistoryView'),
                    onRestoreText: (text, src, tgt) {
                      _textTranslationKey.currentState
                          ?.restoreText(text, src, tgt);
                      setState(() => _currentIndex = 0);
                    },
                  ),
                  const AiEngineStudioView(
                    key: ValueKey('AiEngineStudioView'),
                  ),
                ],
              ),
            ),
            if (isMobile)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MobileDockNav(
                  colors: colors,
                  currentIndex: _currentIndex,
                  tabs: language.tabLabels,
                  icons: _tabIcons,
                  onTabSelected: (index) =>
                      setState(() => _currentIndex = index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    ThemeProvider theme,
    LanguageProvider language,
    AppColors colors,
    bool isMobile,
  ) {
    final timestamp = widget.buildTimestamp ?? _getFallbackBuildTimestamp();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1220;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.headerBg,
        border: Border(
          bottom: BorderSide(color: colors.headerBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo + Title + Version Tag
          InkWell(
            onTap: () => setState(() => _currentIndex = 0),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primaryGlow.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/app_icon.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.appTitle,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (widget.isDebug) ...[
                          const SizedBox(width: 6),
                          PillBadge(
                            label: 'DEBUG',
                            color: colors.accentAmber,
                            bg: colors.accentAmber.withValues(alpha: 0.15),
                            border: colors.accentAmber.withValues(alpha: 0.4),
                            icon: Icons.bug_report_rounded,
                            fontSize: 9.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(
                      width: 130,
                      child: AsymmetricMarqueeText(
                        text: widget.isDebug
                            ? 'v${widget.appVersion} ($timestamp)'
                            : 'v${widget.appVersion}',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: isMobile ? 8 : 20),

          // Sliding Pill Tab Bar (Centered)
          Expanded(
            child: isMobile
                ? const SizedBox.shrink()
                : Center(
                    child: SlidingPillTabBar(
                      colors: colors,
                      currentIndex: _currentIndex,
                      tabs: language.tabLabels,
                      icons: _tabIcons,
                      onTabSelected: (index) =>
                          setState(() => _currentIndex = index),
                    ),
                  ),
          ),

          SizedBox(width: isMobile ? 8 : 12),

          // Dynamic Island Status Capsule with 1-Click Fast AI Engine Switcher
          DynamicIslandCapsule(
            colors: colors,
            isRunning: EngineReadiness.current == 'engine_configured',
            statusText: AppConfig.isLocalAi ? 'LOCAL AI' : 'CLOUD AI',
            subText: (!isMobile && screenWidth > 1100)
                ? (AppConfig.isLocalAi ? 'Qwen GGUF' : 'NVIDIA NIM')
                : null,
            actionHint: AppConfig.isLocalAi ? 'Cloud' : 'Local',
            icon: AppConfig.isLocalAi
                ? Icons.memory_rounded
                : Icons.cloud_done_rounded,
            customColor:
                AppConfig.isLocalAi ? colors.accentEmerald : colors.accentCyan,
            tooltip: language.t(AppConfig.isLocalAi
                ? 'topbar_switch_to_cloud'
                : 'topbar_switch_to_local'),
            onTap: _toggleAiEngine,
            onLongPress: () => setState(() => _currentIndex = 3),
          ),

          const SizedBox(width: 8),

          // LAN OTA Update Alert Button (Visible when update available)
          if (_hasPendingOtaUpdate && _pendingOtaPackage != null) ...[
            TopBarExpandingButton(
              icon: Icon(
                Icons.rocket_launch_rounded,
                color: colors.accentEmerald,
                size: 14,
              ),
              collapsedLabel: isCompact ? null : 'OTA',
              expandedLabel: '🚀 ${_pendingOtaPackage!.version.displayVersion}',
              textColor: colors.accentEmerald,
              isCompact: isCompact,
              tooltip: language.t('topbar_ota_available_tooltip'),
              colors: colors,
              onTap: () {
                showGlassUpdateDialog(
                  context: context,
                  packageInfo: _pendingOtaPackage!,
                  uiLang: language.currentLanguage.code,
                );
              },
            ),
            const SizedBox(width: 6),
          ],

          // 1. Quick Performance Tier Switcher (⚡ Auto / Ultra / Balanced / Lite)
          TopBarExpandingButton(
            icon: Icon(
              theme.effectiveTier.icon,
              color: theme.effectiveTier.color,
              size: 14,
            ),
            collapsedLabel: isCompact ? null : theme.perfLabel,
            expandedLabel: '⚡ ${theme.perfLabel}',
            textColor: theme.effectiveTier.color,
            isCompact: isCompact,
            tooltip: language.t('perf_tooltip'),
            colors: colors,
            onTap: () {
              theme.cyclePerfTier();
              final langCode = language.currentLanguage.code;
              String msg;
              if (langCode == 'ENG') {
                msg =
                    '⚡ Graphic Tier: ${theme.perfLabel} (Optimized for ${theme.cpuCores} CPU Cores)';
              } else if (langCode == 'CN') {
                msg =
                    '⚡ 硬件档位: ${theme.perfLabel} (针对 ${theme.cpuCores} 核处理器优化)';
              } else {
                msg =
                    '⚡ Cấu hình máy: ${theme.perfLabel} (Tự động nhận diện CPU ${theme.cpuCores} Cores)';
              }
              showAppToast(
                context,
                message: msg,
                colors: colors,
                icon: Icons.bolt_rounded,
              );
            },
          ),

          const SizedBox(width: 6),

          // 2. Quick Language Switcher (🌐 VI / ENG / CN)
          TopBarExpandingButton(
            icon: Text(
              language.currentLanguage.flag,
              style: const TextStyle(fontSize: 12),
            ),
            collapsedLabel: isCompact ? null : language.currentLanguage.code,
            expandedLabel:
                '${language.currentLanguage.flag} ${language.currentLanguage.label}',
            textColor: colors.accentCyan,
            isCompact: isCompact,
            tooltip: language.t('lang_tooltip'),
            colors: colors,
            onTap: () {
              language.cycleLanguage();
              showAppToast(
                context,
                message: language.t('lang_tooltip'),
                colors: colors,
                icon: Icons.language_rounded,
              );
            },
          ),

          const SizedBox(width: 6),

          // 3. 1-Click Theme Toggle Button
          TopBarExpandingButton(
            icon: Icon(
              theme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: theme.isDark ? colors.accentAmber : colors.accentPurple,
              size: 14,
            ),
            collapsedLabel: null,
            expandedLabel: language.t(
              theme.isDark ? 'theme_light' : 'theme_dark',
            ),
            textColor: theme.isDark ? colors.accentAmber : colors.accentPurple,
            isCompact: isCompact,
            tooltip:
                '${language.t('theme_tooltip')} (${AppShortcuts.label('Shift+L')})',
            colors: colors,
            onTap: () => theme.toggleTheme(),
          ),

          const SizedBox(width: 6),

          // 4. Glassmorphism Settings Button
          TopBarExpandingButton(
            icon: Icon(
              Icons.settings_rounded,
              color: colors.textSecondary,
              size: 14,
            ),
            collapsedLabel: null,
            expandedLabel: language.t('settings_btn'),
            textColor: colors.accentCyan,
            isCompact: isCompact,
            tooltip:
                '${language.t('settings_btn')} (${AppShortcuts.label(',')})',
            colors: colors,
            onTap: () => _showGlassSettingsDialog(context, theme, language),
          ),
        ],
      ),
    );
  }

  void _showGlassSettingsDialog(
    BuildContext context,
    ThemeProvider theme,
    LanguageProvider language,
  ) {
    final colors = theme.colors;
    final origCardBlur = theme.cardBlur;
    final origCardOpacity = theme.cardOpacity;
    final origDialogBlur = theme.dialogBlur;
    final origDialogOpacity = theme.dialogOpacity;
    final origDropdownBlur = theme.dropdownBlur;
    final origDropdownOpacity = theme.dropdownOpacity;

    double localCardBlur = origCardBlur;
    double localCardOpacity = origCardOpacity;
    double localDialogBlur = origDialogBlur;
    double localDialogOpacity = origDialogOpacity;
    double localDropdownBlur = origDropdownBlur;
    double localDropdownOpacity = origDropdownOpacity;

    int activeTab = 0;

    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return GlassDialog(
              title: language.t('settings_dialog_title'),
              icon: Icons.tune_rounded,
              isDark: theme.isDark,
              width: 700,
              height: 640,
              contentPadding: EdgeInsets.zero,
              blurSigma: localDialogBlur,
              bgOpacity: localDialogOpacity,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    language.t('settings_btn_close'),
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                GlowingActionButton(
                  height: 36,
                  colors: colors,
                  icon: Icons.save_rounded,
                  label: language.t('settings_btn_save'),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
              child: Column(
                children: [
                  _SettingsTabSelector(
                    activeTab: activeTab,
                    colors: colors,
                    language: language,
                    onTabSelected: (index) {
                      setDialogState(() => activeTab = index);
                    },
                  ),
                  Divider(color: colors.subCardBorder, height: 1),
                  Expanded(
                    child: _buildSettingsContent(
                      activeTab: activeTab,
                      colors: colors,
                      theme: theme,
                      language: language,
                      localCardBlur: localCardBlur,
                      localCardOpacity: localCardOpacity,
                      localDialogBlur: localDialogBlur,
                      localDialogOpacity: localDialogOpacity,
                      localDropdownBlur: localDropdownBlur,
                      localDropdownOpacity: localDropdownOpacity,
                      setDialogState: setDialogState,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((saved) {
      if (!mounted || saved == true) return;
      theme.setLiveGlassmorphism(
        cardBlur: origCardBlur,
        cardOpacity: origCardOpacity,
        dialogBlur: origDialogBlur,
        dialogOpacity: origDialogOpacity,
        dropdownBlur: origDropdownBlur,
        dropdownOpacity: origDropdownOpacity,
      );
    });
  }

  Widget _buildSettingsContent({
    required int activeTab,
    required AppColors colors,
    required ThemeProvider theme,
    required LanguageProvider language,
    required double localCardBlur,
    required double localCardOpacity,
    required double localDialogBlur,
    required double localDialogOpacity,
    required double localDropdownBlur,
    required double localDropdownOpacity,
    required StateSetter setDialogState,
  }) {
    switch (activeTab) {
      case 0:
        return _SettingsGeneralTab(
          colors: colors,
          theme: theme,
          language: language,
          localCardBlur: localCardBlur,
          localCardOpacity: localCardOpacity,
          localDialogBlur: localDialogBlur,
          localDialogOpacity: localDialogOpacity,
          localDropdownBlur: localDropdownBlur,
          localDropdownOpacity: localDropdownOpacity,
          onCardBlurChanged: (v) {
            setDialogState(() => localCardBlur = v);
            theme.setLiveGlassmorphism(cardBlur: v);
          },
          onCardOpacityChanged: (v) {
            setDialogState(() => localCardOpacity = v);
            theme.setLiveGlassmorphism(cardOpacity: v);
          },
          onDialogBlurChanged: (v) {
            setDialogState(() => localDialogBlur = v);
            theme.setLiveGlassmorphism(dialogBlur: v);
          },
          onDialogOpacityChanged: (v) {
            setDialogState(() => localDialogOpacity = v);
            theme.setLiveGlassmorphism(dialogOpacity: v);
          },
          onDropdownBlurChanged: (v) {
            setDialogState(() => localDropdownBlur = v);
            theme.setLiveGlassmorphism(dropdownBlur: v);
          },
          onDropdownOpacityChanged: (v) {
            setDialogState(() => localDropdownOpacity = v);
            theme.setLiveGlassmorphism(dropdownOpacity: v);
          },
          onResetDefaults: () {
            setDialogState(() {
              localCardBlur = 20.0;
              localCardOpacity = 0.25;
              localDialogBlur = 20.0;
              localDialogOpacity = 0.85;
              localDropdownBlur = 20.0;
              localDropdownOpacity = 0.86;
            });
            theme.setLiveGlassmorphism(
              cardBlur: 20.0,
              cardOpacity: 0.25,
              dialogBlur: 20.0,
              dialogOpacity: 0.85,
              dropdownBlur: 20.0,
              dropdownOpacity: 0.86,
            );
          },
        );
      case 1:
        return _SettingsOtaTab(colors: colors, language: language);
      case 2:
        return _SettingsShortcutsAndAboutTab(
          colors: colors,
          theme: theme,
          language: language,
          appVersion: widget.appVersion,
          isDebug: widget.isDebug,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getFallbackBuildTimestamp() {
    try {
      final exe = File(Platform.resolvedExecutable);
      final so = File(
        '${exe.parent.path}${Platform.pathSeparator}data${Platform.pathSeparator}app.so',
      );
      final f = so.existsSync() ? so : (exe.existsSync() ? exe : null);
      if (f != null) {
        final dt = f.lastModifiedSync();
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
