import 'package:flutter/material.dart';
import 'app_colors.dart';

const win11DarkColors = AppColors(
  bgPrimary: Colors.transparent, // Let Acrylic / Mesh gradient bleed through
  bgSecondary: Color(0x33000000), // Soft dark tint
  cardBg: Color(0xD40F172A), // ~83% rich dark navy slate
  cardHoverBg: Color(0xEA1E293B),
  subCardBg: Color(0x661E293B), // ~40% slate sub-card
  subCardBorder: Color(0x2E334155),
  sidebarBg: Color(0xD00A0F1D),
  headerBg: Color(0xE00B1120),
  headerBorder: Color(0x26FFFFFF),
  textPrimary: Color(0xFFF8FAFC), // Slate 50
  textSecondary: Color(0xFFCBD5E1), // Slate 300
  textMuted: Color(0xFF94A3B8), // Slate 400
  borderDefault: Color(0x24FFFFFF),
  accentColor: Color(0xFF0066FF),
  primaryGlow: Color(0x590066FF),
  accentCyan: Color(0xFF38BDF8),
  accentEmerald: Color(0xFF34D399),
  accentAmber: Color(0xFFFBBF24),
  accentRose: Color(0xFFFB7185),
  accentPurple: Color(0xFFC084FC),
  orb1: Color(0xFF0066FF),
  orb2: Color(0xFFA855F7),
  orb3: Color(0xFF00D2FF),
  orbOpacity: 0.25,
  glassBg: Color(0xD40F172A),
  glassBorder: Color(0x26FFFFFF),
  glassHighlight: Color(0x33FFFFFF),
);

const win11LightColors = AppColors(
  bgPrimary: Colors.transparent,
  bgSecondary: Color(0x33FFFFFF),
  cardBg: Color(0xDCFFFFFF), // ~86% frosted white, eliminates bleed-through
  cardHoverBg: Color(0xF2FFFFFF),
  subCardBg: Color(0x75F1F5F9), // Soft slate sub-surface
  subCardBorder: Color(0x50CBD5E1),
  sidebarBg: Color(0xD8F8FAFC),
  headerBg: Color(0xEAFFFFFF),
  headerBorder: Color(0x33CBD5E1),
  textPrimary: Color(0xFF0F172A), // Slate 900
  textSecondary: Color(0xFF334155), // Slate 700 - high contrast
  textMuted: Color(0xFF64748B), // Slate 500
  borderDefault: Color(0x40CBD5E1),
  accentColor: Color(0xFF0066FF),
  primaryGlow: Color(0x440066FF),
  accentCyan: Color(0xFF00D2FF),
  accentEmerald: Color(0xFF10B981),
  accentAmber: Color(0xFFF59E0B),
  accentRose: Color(0xFFF43F5E),
  accentPurple: Color(0xFF8B5CF6),
  orb1: Color(0xFF0066FF),
  orb2: Color(0xFFA855F7),
  orb3: Color(0xFF00D2FF),
  orbOpacity: 0.24,
  glassBg: Color(0xDCFFFFFF),
  glassBorder: Color(0x50CBD5E1),
  glassHighlight: Color(0x99FFFFFF),
);
