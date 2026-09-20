import 'package:flutter/material.dart';
import 'styles.dart';

class StylesWin10 {
  static const dark = AppColors(
    bgPrimary: Colors.transparent, // fully transparent for Aero Blur
    bgSecondary: Color(0x80121212), // 50% opacity main background
    bgTertiary: Color(0xB31F1F1F), // 70% opacity sidebar background
    bgCard: Color(0xD92C2C2C), // 85% opacity card/panel background
    bgHover: Color(0x1F00ADB5), // soft cyan hover
    textPrimary: Color(0xFFEEEEEE),
    textSecondary: Color(0xFFB0B0B0),
    textMuted: Color(0xFF757575),
    borderDefault: Color(0x1AFFFFFF), // subtle white border
    borderHighlight: Color(0xFF00ADB5), // Cyan accent
    linkAccent: Color(0xFF00ADB5), // Cyan accent
    targetAccent: Color(0xFF34D399), // Emerald accent for targets
    statusActive: Color(0xFF34D399),
    statusRemoved: Color(0xFFF87171),
    statusChanged: Color(0xFFFBBF24),
    brightness: Brightness.dark,
  );

  static const light = AppColors(
    bgPrimary: Colors.transparent, // fully transparent for Aero Blur
    bgSecondary: Color(0x80FAFAFA), // 50% opacity main background
    bgTertiary: Color(0xB3F3F3F3), // 70% opacity sidebar background
    bgCard: Color(0xD9FFFFFF), // 85% opacity card/panel background
    bgHover: Color(0x1900ADB5),
    textPrimary: Color(0xFF1F1F1F),
    textSecondary: Color(0xFF757575),
    textMuted: Color(0xFF9E9E9E),
    borderDefault: Color(0x1A000000), // subtle black border
    borderHighlight: Color(0xFF00ADB5), // Cyan accent
    linkAccent: Color(0xFF00ADB5), // Cyan accent
    targetAccent: Color(0xFF00ADB5),
    statusActive: Color(0xFF16A34A),
    statusRemoved: Color(0xFFDC2626),
    statusChanged: Color(0xFFD97706),
    brightness: Brightness.light,
  );
}
