// lib/theme/window_effect_helper.dart
// Manages native Windows composition backdrop effects (Acrylic, Aero, Mica, Tabbed)
// Ensures zero-alpha guards and correct DWM initialization timing.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

class WindowEffectHelper {
  /// Detects whether the host operating system is Windows 11 (build >= 22000)
  static bool isWindows11() {
    if (!Platform.isWindows) return false;
    try {
      final versionStr = Platform.operatingSystemVersion;
      final match = RegExp(r'Build\s+(\d+)').firstMatch(versionStr);
      if (match != null) {
        final buildNumber = int.tryParse(match.group(1) ?? '') ?? 0;
        return buildNumber >= 22000;
      }
    } catch (_) {}
    return false;
  }

  static WindowEffect parseEffect(String id, {bool isWin11 = false}) {
    switch (id.toLowerCase()) {
      case 'acrylic':
        return WindowEffect.acrylic;
      case 'aero':
        return WindowEffect.aero;
      case 'mica':
        return WindowEffect.mica;
      case 'tabbed':
        return WindowEffect.tabbed;
      case 'disabled':
        return WindowEffect.disabled;
      case 'auto':
      default:
        return isWin11 ? WindowEffect.acrylic : WindowEffect.aero;
    }
  }

  static String effectToId(WindowEffect effect) {
    switch (effect) {
      case WindowEffect.acrylic:
        return 'acrylic';
      case WindowEffect.aero:
        return 'aero';
      case WindowEffect.mica:
        return 'mica';
      case WindowEffect.tabbed:
        return 'tabbed';
      case WindowEffect.disabled:
        return 'disabled';
      default:
        return 'acrylic';
    }
  }

  static Future<void> apply({
    required WindowEffect effect,
    required bool isDark,
    bool enableTransparency = true,
  }) async {
    if (!Platform.isWindows) return;
    try {
      if (effect == WindowEffect.disabled || !enableTransparency) {
        await Window.setEffect(effect: WindowEffect.disabled);
        return;
      }

      // Safe non-zero alpha tint to prevent Windows DWM zero-alpha solid color fallback
      final Color tintColor = isDark
          ? const Color(0x1F0A0C1C) // ~12% dark slate navy tint
          : const Color(0x1FF8FAFC); // ~12% light cool white tint

      await Window.setEffect(effect: effect, color: tintColor, dark: isDark);
    } catch (e) {
      debugPrint('WindowEffectHelper.apply error: $e');
    }
  }
}
