import 'package:flutter/material.dart';
import 'styles.dart';

class StylesWin11 {
  static const dark = AppColors(
    bgPrimary: Color(0x1A000000),       // 10% opacity black for Acrylic
    bgSecondary: Color(0x592D2D2D),     // 35% opacity main background
    bgTertiary: Color(0x331C1C1C),      // 20% opacity sidebar background
    bgCard: Color(0x592D2D2D),          // 35% opacity card/panel background
    bgHover: Color(0x1F00ADB5),         // soft cyan hover
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCCCCCC),
    textMuted: Color(0xFF888888),
    borderDefault: Color(0x1AFFFFFF),   // subtle white border
    borderHighlight: Color(0xFF00ADB5), // Cyan accent
    linkAccent: Color(0xFF00ADB5),      // Cyan accent
    targetAccent: Color(0xFF34D399),    // Emerald accent for targets
    statusActive: Color(0xFF34D399),
    statusRemoved: Color(0xFFF87171),
    statusChanged: Color(0xFFFBBF24),
    brightness: Brightness.dark,
  );

  static const light = AppColors(
    bgPrimary: Color(0x1AFAFAFA),       // 10% opacity white for Acrylic
    bgSecondary: Color(0x59FFFFFF),     // 35% opacity main background
    bgTertiary: Color(0x33E5E5E5),      // 20% opacity sidebar background
    bgCard: Color(0x59FFFFFF),          // 35% opacity card/panel background
    bgHover: Color(0x1900ADB5),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF555555),
    textMuted: Color(0xFF777777),
    borderDefault: Color(0x1A000000),   // subtle black border
    borderHighlight: Color(0xFF00ADB5), // Cyan accent
    linkAccent: Color(0xFF00ADB5),      // Cyan accent
    targetAccent: Color(0xFF00ADB5),
    statusActive: Color(0xFF16A34A),
    statusRemoved: Color(0xFFDC2626),
    statusChanged: Color(0xFFD97706),
    brightness: Brightness.light,
  );
}
