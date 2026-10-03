// lib/modules/power_coordinator.dart
// Centralized Power and UI Activity Coordinator for Flutter Desktop.
// Eliminates CPU/GPU rendering overhead when window is hidden in tray,
// minimized to taskbar, unfocused, or idle (>12s).

import 'dart:async';
import 'package:flutter/foundation.dart';

class PowerCoordinator extends ChangeNotifier {
  static PowerCoordinator _instance = PowerCoordinator._internal();
  static PowerCoordinator get instance => _instance;

  @visibleForTesting
  static void setMockInstance(PowerCoordinator mock) {
    _instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance.dispose();
    _instance = PowerCoordinator._internal();
  }

  PowerCoordinator._internal({Duration? idleTimeout})
      : _idleTimeout = idleTimeout ?? const Duration(seconds: 12) {
    _resetIdleTimer();
  }

  factory PowerCoordinator({Duration? idleTimeout}) {
    if (idleTimeout != null) {
      _instance.idleTimeout = idleTimeout;
    }
    return _instance;
  }

  bool _isVisible = true;
  bool _isFocused = true;
  bool _isMinimized = false;
  bool _isIdle = false;
  Duration _idleTimeout;
  Timer? _idleTimer;
  int _sessionEpoch = 0;
  bool _isDisposed = false;

  bool get isVisible => _isVisible;
  bool get isFocused => _isFocused;
  bool get isMinimized => _isMinimized;
  bool get isIdle => _isIdle;
  int get sessionEpoch => _sessionEpoch;

  /// Global TickerMode gating: Active when visible, NOT minimized, AND focused.
  /// When false, mutes continuous Flutter UI tickers and rendering pipeline.
  bool get isUiActive => _isVisible && !_isMinimized && _isFocused;

  /// Heavy decoration policy (e.g. 85px Gaussian blur MeshOrb):
  /// Active only when UI is fully active and the user is actively interacting.
  /// Pauses after 12s of user inactivity to reduce idle GPU power consumption.
  bool get isDecorActive => isUiActive && !_isIdle;

  Duration get idleTimeout => _idleTimeout;
  set idleTimeout(Duration value) {
    _idleTimeout = value;
    if (isUiActive) {
      _resetIdleTimer();
    }
  }

  /// Records user pointer, keyboard, or wheel interaction.
  /// Resets the idle timeout back to active state.
  void recordUserActivity() {
    if (_isDisposed) return;

    final wasIdle = _isIdle;
    _isIdle = false;
    _resetIdleTimer();

    if (wasIdle) {
      notifyListeners();
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_isDisposed || !isUiActive) return;

    _idleTimer = Timer(_idleTimeout, () {
      if (_isDisposed) return;
      if (!_isIdle) {
        _isIdle = true;
        notifyListeners();
      }
    });
  }

  @visibleForTesting
  void cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// Explicitly updates window visibility (e.g. tray hide/show).
  void setWindowVisibility(bool visible) {
    if (_isDisposed || _isVisible == visible) return;
    _isVisible = visible;
    _sessionEpoch++;

    if (!visible) {
      _idleTimer?.cancel();
    } else if (isUiActive) {
      _resetIdleTimer();
    }

    notifyListeners();
  }

  /// Updates window focus status (e.g. onWindowFocus / onWindowBlur).
  void setWindowFocus(bool focused) {
    if (_isDisposed || _isFocused == focused) return;
    _isFocused = focused;
    _sessionEpoch++;

    if (focused) {
      _isIdle = false;
      _resetIdleTimer();
    } else {
      _idleTimer?.cancel();
    }

    notifyListeners();
  }

  /// Updates window minimized status (e.g. onWindowMinimize / onWindowRestore).
  void setWindowMinimized(bool minimized) {
    if (_isDisposed || _isMinimized == minimized) return;
    _isMinimized = minimized;
    _sessionEpoch++;

    if (minimized) {
      _idleTimer?.cancel();
    } else if (isUiActive) {
      _resetIdleTimer();
    }

    notifyListeners();
  }

  /// Synchronizes complete native state snapshot safely.
  void syncNativeState({
    required bool isVisible,
    required bool isFocused,
    required bool isMinimized,
  }) {
    if (_isDisposed) return;
    final changed = _isVisible != isVisible ||
        _isFocused != isFocused ||
        _isMinimized != isMinimized;

    _isVisible = isVisible;
    _isFocused = isFocused;
    _isMinimized = isMinimized;
    _sessionEpoch++;

    if (isUiActive) {
      _resetIdleTimer();
    } else {
      _idleTimer?.cancel();
    }

    if (changed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _idleTimer?.cancel();
    _idleTimer = null;
    super.dispose();
  }
}
