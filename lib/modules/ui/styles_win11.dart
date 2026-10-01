import 'package:flutter/material.dart';
import 'styles.dart';

class StylesWin11 {
  static const dark = AppColors(
    bgPrimary: Color(
        0xDD111827), // ~87% opacity Dark Slate for Acrylic blur & solid readability
    bgSecondary: Color(0xEE1E293B), // ~93% opacity main cards
    bgTertiary: Color(0xCC0F172A), // ~80% opacity control background
    bgCard: Color(0xF21E293B), // ~95% opacity card/panel background
    bgHover: Color(0x1F00ADB5), // soft cyan hover
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCCCCCC),
    textMuted: Color(0xFF888888),
    borderDefault: Color(0x2EFFFFFF), // subtle white border
    borderHighlight: Color(0xFF00ADB5), // Cyan accent
    linkAccent: Color(0xFF00ADB5), // Cyan accent
    targetAccent: Color(0xFF34D399), // Emerald accent for targets
    statusActive: Color(0xFF34D399),
    statusRemoved: Color(0xFFF87171),
    statusChanged: Color(0xFFFBBF24),
    brightness: Brightness.dark,
  );

  static const light = AppColors(
    bgPrimary: Color(0xEBFAFAFA), // ~92% opacity light base
    bgSecondary: Color(0xF5FFFFFF), // ~96% opacity cards
    bgTertiary: Color(0xCCE2E8F0), // ~80% opacity controls
    bgCard: Color(0xF8FFFFFF), // ~97% opacity card background
    bgHover: Color(0x1900ADB5),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
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
