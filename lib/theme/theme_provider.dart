import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'app_colors.dart';
import 'styles_win10.dart';
import 'styles_win11.dart';
import 'window_effect_helper.dart';
import '../modules/app_config.dart';

/// Performance Tier Mode for Graphic & Hardware Tuning.
enum PerfTierMode {
  auto('auto', 'Auto'),
  ultra('ultra', 'Ultra'),
  balanced('balanced', 'Balanced'),
  lite('lite', 'Lite');

  final String id;
  final String label;
  const PerfTierMode(this.id, this.label);
}

/// Effective Hardware Graphic Tier
enum HardwareTier {
  ultra('Ultra', '120 FPS • Max Glass', Icons.bolt_rounded, Color(0xFF0066FF)),
  balanced(
    'Balanced',
    '60 FPS • Laptop Opt',
    Icons.balance_rounded,
    Color(0xFF10B981),
  ),
  lite('Lite', 'Low Power • Zero Lag', Icons.eco_rounded, Color(0xFFF59E0B));

  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  const HardwareTier(this.label, this.desc, this.icon, this.color);
}

class ThemeProvider extends ChangeNotifier {
  static const MethodChannel _nativeChannel =
      MethodChannel('ja_translate/theme');

  String _themeMode = 'dark';
  bool _isWin11 = false;

  // Performance & Graphic Tier Profiling
  PerfTierMode _perfMode = PerfTierMode.auto;
  late HardwareTier _detectedTier;
  int _cpuCores = 4;
  int _hardwareScore = 50;

  // Glass defaults with high opacity to eliminate see-through ghosting
  double _cardBlur = 20.0;
  double _cardOpacity = 0.86;
  double _dialogBlur = 24.0;
  double _dialogOpacity = 0.92;
  double _dropdownBlur = 20.0;
  double _dropdownOpacity = 0.92;

  ThemeProvider({String? initialMode}) {
    _themeMode =
        initialMode ?? AppConfig.get('SETTINGS', 'theme', defaultValue: 'dark');
    _detectWindowsVersion();
    _profileHardware();
    _applyNativeTheme();
  }

  void _detectWindowsVersion() {
    _isWin11 = WindowEffectHelper.isWindows11();
  }

  void _profileHardware() {
    try {
      _cpuCores = Platform.numberOfProcessors;
    } catch (_) {
      _cpuCores = 4;
    }

    int score = 50;
    if (_cpuCores >= 8) {
      score += 30;
    } else if (_cpuCores >= 4) {
      score += 10;
    } else {
      score -= 25;
    }

    if (_isWin11) score += 10;

    _hardwareScore = score.clamp(10, 100);
    if (_hardwareScore < 40) {
      _detectedTier = HardwareTier.lite;
    } else if (_hardwareScore < 70) {
      _detectedTier = HardwareTier.balanced;
    } else {
      _detectedTier = HardwareTier.ultra;
    }
  }

  HardwareTier get effectiveTier {
    switch (_perfMode) {
      case PerfTierMode.ultra:
        return HardwareTier.ultra;
      case PerfTierMode.balanced:
        return HardwareTier.balanced;
      case PerfTierMode.lite:
        return HardwareTier.lite;
      case PerfTierMode.auto:
        return _detectedTier;
    }
  }

  String get perfLabel {
    if (_perfMode == PerfTierMode.auto) {
      return 'Auto (${_detectedTier.label})';
    }
    return _perfMode.label;
  }

  void cyclePerfTier() {
    switch (_perfMode) {
      case PerfTierMode.auto:
        setPerfTierMode(PerfTierMode.ultra);
        break;
      case PerfTierMode.ultra:
        setPerfTierMode(PerfTierMode.balanced);
        break;
      case PerfTierMode.balanced:
        setPerfTierMode(PerfTierMode.lite);
        break;
      case PerfTierMode.lite:
        setPerfTierMode(PerfTierMode.auto);
        break;
    }
  }

  void setPerfTierMode(PerfTierMode mode) {
    _perfMode = mode;
    _applyHardwareTuning();
    notifyListeners();
  }

  void _applyHardwareTuning({bool notify = false}) {
    switch (effectiveTier) {
      case HardwareTier.ultra:
        _cardBlur = 24.0;
        _cardOpacity = 0.86;
        _dialogBlur = 24.0;
        _dialogOpacity = 0.92;
        _dropdownBlur = 20.0;
        _dropdownOpacity = 0.92;
        break;
      case HardwareTier.balanced:
        _cardBlur = 16.0;
        _cardOpacity = 0.88;
        _dialogBlur = 18.0;
        _dialogOpacity = 0.94;
        _dropdownBlur = 14.0;
        _dropdownOpacity = 0.94;
        break;
      case HardwareTier.lite:
        _cardBlur = 0.0;
        _cardOpacity = 0.96;
        _dialogBlur = 8.0;
        _dialogOpacity = 0.98;
        _dropdownBlur = 0.0;
        _dropdownOpacity = 0.98;
        break;
    }
    if (notify) notifyListeners();
  }

  String get themeMode => _themeMode;

  bool get isDark {
    if (_themeMode == 'dark') return true;
    if (_themeMode == 'light') return false;
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  bool get isWin11 => _isWin11;
  int get cpuCores => _cpuCores;

  double get cardBlur => _cardBlur;
  double get cardOpacity => _cardOpacity;
  double get dialogBlur => _dialogBlur;
  double get dialogOpacity => _dialogOpacity;
  double get dropdownBlur => _dropdownBlur;
  double get dropdownOpacity => _dropdownOpacity;

  AppColors get colors {
    if (isDark) {
      return _isWin11 ? win11DarkColors : win10DarkColors;
    } else {
      return _isWin11 ? win11LightColors : win10LightColors;
    }
  }

  /// 1-Click Direct Toggle between Light and Dark
  void toggleTheme() {
    setThemeMode(isDark ? 'light' : 'dark');
  }

  void setThemeMode(String mode) {
    _themeMode = mode;
    AppConfig.set('SETTINGS', 'theme', mode);
    _applyNativeTheme();
    notifyListeners();
  }

  Future<void> _applyNativeTheme() async {
    if (!Platform.isWindows) return;
    try {
      await _nativeChannel.invokeMethod('setTheme', isDark ? 'dark' : 'light');
      // The native runner owns composition; do not overwrite it with a plugin.
      if (AppConfig.enableTransparency) return;
    } catch (_) {}

    await WindowEffectHelper.apply(
      effect: _isWin11 ? WindowEffect.acrylic : WindowEffect.aero,
      isDark: isDark,
      enableTransparency: AppConfig.enableTransparency,
    );
  }

  /// Reset to standard tuning defaults
  void resetToDefaults() {
    _cardBlur = 20.0;
    _cardOpacity = 0.86;
    _dialogBlur = 24.0;
    _dialogOpacity = 0.92;
    _dropdownBlur = 20.0;
    _dropdownOpacity = 0.92;
    notifyListeners();
  }

  /// Real-time live tuning for Glassmorphism sliders
  void setLiveGlassmorphism({
    double? cardBlur,
    double? cardOpacity,
    double? dialogBlur,
    double? dialogOpacity,
    double? dropdownBlur,
    double? dropdownOpacity,
  }) {
    if (cardBlur != null) _cardBlur = cardBlur;
    if (cardOpacity != null) _cardOpacity = cardOpacity;
    if (dialogBlur != null) _dialogBlur = dialogBlur;
    if (dialogOpacity != null) _dialogOpacity = dialogOpacity;
    if (dropdownBlur != null) _dropdownBlur = dropdownBlur;
    if (dropdownOpacity != null) _dropdownOpacity = dropdownOpacity;
    notifyListeners();
  }
}
