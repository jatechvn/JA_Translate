import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

/// Initializes desktop window management following the native C++ runner architecture
/// (as implemented in JA_MES_Tool and documented in flutter-windows-themer).
///
/// On Windows, composition blur (Windows 11 Acrylic & Windows 10 Aero) is handled
/// directly at OS startup by windows/runner/theme_win11.cpp & theme_win10.cpp with
/// zero latency, zero flicker, and zero plugin interference.
///
/// This helper initializes [windowManager] for window state, resize constraints,
/// and event listeners, and ensures the window is explicitly shown and focused
/// without resetting the native C++ DWM glass composition.
Future<void> initGlassWindow({
  String title = 'JA Application',
  Size size = const Size(1200, 820),
  Size minSize = const Size(760, 520),
  bool center = true,
}) async {
  if (kIsWeb ||
      (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS)) {
    return;
  }

  try {
    await windowManager.ensureInitialized();

    if (Platform.isWindows) {
      try {
        await Window.initialize();
      } catch (e) {
        debugPrint('Window.initialize error: $e');
      }
    }

    final windowOptions = WindowOptions(
      size: size,
      minimumSize: minSize,
      center: center,
      skipTaskbar: false,
      title: title,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (e) {
    debugPrint('Window manager error: $e');
  }
}
