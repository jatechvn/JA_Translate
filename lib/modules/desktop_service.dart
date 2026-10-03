// lib/modules/desktop_service.dart
// System Tray, Global Hotkeys and Screen Snip service for Windows Desktop

import 'dart:io';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'app_config.dart';
import 'llama_service.dart';
import 'power_coordinator.dart';

// Win32 FFI for high-speed, zero-CPU clipboard monitoring
final DynamicLibrary? _user32 =
    Platform.isWindows ? DynamicLibrary.open('user32.dll') : null;
final int Function()? _getClipboardSequenceNumber =
    _user32?.lookupFunction<Uint32 Function(), int Function()>(
        'GetClipboardSequenceNumber');
final int Function(int)? _isClipboardFormatAvailable =
    _user32?.lookupFunction<Int32 Function(Uint32), int Function(int)>(
        'IsClipboardFormatAvailable');

class DesktopService with TrayListener, WindowListener {
  static final DesktopService _instance = DesktopService._internal();
  factory DesktopService() => _instance;
  DesktopService._internal();

  VoidCallback? onQuickTranslateHotkey;
  VoidCallback? onScreenSnipHotkey;

  bool _isInitialized = false;

  Future<void> initialize({
    VoidCallback? onQuickTranslate,
    VoidCallback? onScreenSnip,
  }) async {
    if (_isInitialized || !Platform.isWindows) return;

    onQuickTranslateHotkey = onQuickTranslate;
    onScreenSnipHotkey = onScreenSnip;

    try {
      // 1. Initialize Hotkey Manager
      await hotKeyManager.unregisterAll();

      // Alt + Q -> Bring window to front
      final hotKeyShow = HotKey(
        key: PhysicalKeyboardKey.keyQ,
        modifiers: [HotKeyModifier.alt],
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        hotKeyShow,
        keyDownHandler: (hotKey) {
          bringToFront();
          onQuickTranslateHotkey?.call();
        },
      );

      // Alt + S -> Screen Snip & Translate
      final hotKeySnip = HotKey(
        key: PhysicalKeyboardKey.keyS,
        modifiers: [HotKeyModifier.alt],
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        hotKeySnip,
        keyDownHandler: (hotKey) {
          onScreenSnipHotkey?.call();
        },
      );

      // 2. Initialize Tray Manager
      trayManager.addListener(this);
      windowManager.addListener(this);

      // Synchronize initial native visibility and focus
      try {
        final isVis = await windowManager.isVisible();
        final isFoc = await windowManager.isFocused();
        final isMin = await windowManager.isMinimized();
        PowerCoordinator.instance.syncNativeState(
          isVisible: isVis,
          isFocused: isFoc,
          isMinimized: isMin,
        );
      } catch (_) {}

      // Set tray icon (use default or app icon)
      try {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final iconPath = '$exeDir/data/flutter_assets/assets/app_icon.ico';
        if (File(iconPath).existsSync()) {
          await trayManager.setIcon(iconPath);
        }
      } catch (_) {}

      await trayManager.setToolTip('JA Translate');
      await _updateTrayMenu();

      // Prevent exit on window close to allow tray minimize
      await windowManager.setPreventClose(true);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing DesktopService: $e');
    }
  }

  static Future<void> bringToFront() async {
    try {
      PowerCoordinator.instance.setWindowVisibility(true);
      PowerCoordinator.instance.setWindowMinimized(false);

      // 1. Explicitly ensure taskbar presence is not suppressed
      await windowManager.setSkipTaskbar(false);

      // 2. If minimized, restore it back to normal
      final isMin = await windowManager.isMinimized();
      if (isMin) {
        await windowManager.restore();
      }

      // 3. If hidden, ensure it is shown
      final isVis = await windowManager.isVisible();
      if (!isVis) {
        await windowManager.show();
      }

      // 4. Show and focus window
      await windowManager.show();
      await windowManager.focus();
      PowerCoordinator.instance.setWindowFocus(true);

      // 5. Force foreground activation over other apps via momentary alwaysOnTop pulse
      try {
        await windowManager.setAlwaysOnTop(true);
        await Future.delayed(const Duration(milliseconds: 60));
        await windowManager.setAlwaysOnTop(false);
      } catch (_) {}
    } catch (e) {
      debugPrint('bringToFront error: $e');
    }
  }

  static int _getClipboardSeq() {
    if (!Platform.isWindows || _getClipboardSequenceNumber == null) return 0;
    try {
      return _getClipboardSequenceNumber!();
    } catch (_) {
      return 0;
    }
  }

  static bool _hasClipboardImage() {
    if (!Platform.isWindows || _isClipboardFormatAvailable == null) {
      return false;
    }
    try {
      // CF_BITMAP = 2, CF_DIB = 8, CF_DIBV5 = 17
      return _isClipboardFormatAvailable!(8) != 0 ||
          _isClipboardFormatAvailable!(2) != 0 ||
          _isClipboardFormatAvailable!(17) != 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _saveClipboardImage(String targetPath) async {
    try {
      final script = '''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
\$img = [System.Windows.Forms.Clipboard]::GetImage()
if (\$img -ne \$null) {
  \$img.Save('$targetPath', [System.Drawing.Imaging.ImageFormat]::Png)
  \$img.Dispose()
  Write-Output "OK"
}
''';
      final res =
          await Process.run('powershell', ['-NoProfile', '-Command', script]);
      return res.stdout.toString().contains('OK');
    } catch (e) {
      debugPrint('Error saving clipboard image: $e');
      return false;
    }
  }

  Future<void> _updateTrayMenu() async {
    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Open JA Translate (Alt+Q)',
        ),
        MenuItem(
          key: 'snip_translate',
          label: 'Screen Snip & Translate (Alt+S)',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    bringToFront();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  /// Cleanly terminate the application, ensuring child services and native processes exit
  static Future<void> quitApplication() async {
    try {
      await LlamaService().stopServer();
    } catch (_) {}
    try {
      await windowManager.destroy();
    } catch (_) {}
    exit(0);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        bringToFront();
        break;
      case 'snip_translate':
        bringToFront();
        onScreenSnipHotkey?.call();
        break;
      case 'exit_app':
        await quitApplication();
        break;
    }
  }

  @override
  void onWindowClose() async {
    final minimizeToTray = AppConfig.get(
          'SETTINGS',
          'minimize_to_tray_on_close',
          defaultValue: 'false',
        ) ==
        'true';

    if (minimizeToTray) {
      // User opted to keep app running in tray for hotkeys Alt+Q / Alt+S
      PowerCoordinator.instance.setWindowVisibility(false);
      try {
        await windowManager.hide();
      } catch (e) {
        debugPrint('windowManager.hide failed: $e');
        try {
          final isVis = await windowManager.isVisible();
          PowerCoordinator.instance.setWindowVisibility(isVis);
        } catch (_) {}
      }
    } else {
      // Clean, complete shutdown — leaves no lingering tasks in Task Manager
      await quitApplication();
    }
  }

  @override
  void onWindowFocus() {
    PowerCoordinator.instance.setWindowFocus(true);
  }

  @override
  void onWindowBlur() {
    PowerCoordinator.instance.setWindowFocus(false);
  }

  @override
  void onWindowMinimize() {
    PowerCoordinator.instance.setWindowMinimized(true);
  }

  @override
  void onWindowRestore() {
    PowerCoordinator.instance.setWindowMinimized(false);
  }

  /// Launch Windows native Snipping Tool and capture result from Clipboard
  static Future<String?> captureScreenSnip() async {
    if (!Platform.isWindows) return null;

    try {
      // 1. Ensure window remains in taskbar and minimize it so user can snip screen
      // IMPORTANT: NEVER use windowManager.hide() here because SW_HIDE strips the app from taskbar!
      await windowManager.setSkipTaskbar(false);
      await windowManager.minimize();
      await Future.delayed(const Duration(milliseconds: 250));

      // 2. Launch Windows 10/11 native screen snipping tool
      Process.run('explorer.exe', ['ms-screenclip:']);

      // 3. Monitor clipboard using fast Win32 sequence checking
      final tempDir = await getTemporaryDirectory();
      final outputPng =
          '${tempDir.path}/snip_${DateTime.now().millisecondsSinceEpoch}.png';

      final initialSeq = _getClipboardSeq();
      String? capturedPath;

      // Poll every 100ms with zero CPU overhead (max 60 iterations = 6 seconds)
      for (var i = 0; i < 60; i++) {
        await Future.delayed(const Duration(milliseconds: 100));

        final currentSeq = _getClipboardSeq();
        // If clipboard sequence changed and contains an image, grab it immediately!
        if ((currentSeq != initialSeq || i > 15) && _hasClipboardImage()) {
          final saved = await _saveClipboardImage(outputPng);
          if (saved && File(outputPng).existsSync()) {
            capturedPath = outputPng;
            break;
          }
        }

        // Early break: if user manually restored or focused JA Translate, snip was cancelled
        if (i >= 10) {
          final isMin = await windowManager.isMinimized();
          if (!isMin && await windowManager.isFocused()) {
            break;
          }
        }
      }

      // 4. Restore window to foreground and guarantee taskbar visibility
      await bringToFront();

      // If user cancelled or timed out, ensure any stuck ScreenClippingHost is cleaned up
      if (capturedPath == null) {
        await cleanupStuckSnippingTool();
      }

      return capturedPath;
    } catch (e) {
      debugPrint('Screen snip error: $e');
      await bringToFront();
      await cleanupStuckSnippingTool();
      return null;
    }
  }

  /// Clean up any lingering ScreenClippingHost process so Win+Shift+S is never locked
  static Future<void> cleanupStuckSnippingTool() async {
    if (!Platform.isWindows) return;
    try {
      await Process.run('taskkill', ['/F', '/IM', 'ScreenClippingHost.exe']);
    } catch (_) {}
  }

  /// Read an image from clipboard directly and save to a temporary file
  static Future<String?> getClipboardImage() async {
    if (!Platform.isWindows) return null;
    if (!_hasClipboardImage()) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPng =
          '${tempDir.path}/clip_${DateTime.now().millisecondsSinceEpoch}.png';
      final saved = await _saveClipboardImage(outputPng);
      if (saved && File(outputPng).existsSync()) {
        return outputPng;
      }
    } catch (e) {
      debugPrint('Error getting clipboard image: $e');
    }
    return null;
  }

  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }
}
