// lib/modules/tts_service.dart
// Text-to-Speech service supporting offline Windows Speech and edge-compatible speech

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  static String? _currentSpeakingText;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux ||
          Platform.isAndroid ||
          Platform.isIOS) {
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);

        _flutterTts.setStartHandler(() {
          isSpeaking.value = true;
        });

        _flutterTts.setCompletionHandler(() {
          isSpeaking.value = false;
          _currentSpeakingText = null;
        });

        _flutterTts.setCancelHandler(() {
          isSpeaking.value = false;
          _currentSpeakingText = null;
        });

        _flutterTts.setErrorHandler((_) {
          isSpeaking.value = false;
          _currentSpeakingText = null;
        });
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  /// Convert application language code to TTS locale
  static String _resolveLocale(String langCode) {
    switch (langCode.toUpperCase()) {
      case 'VN':
      case 'VI':
        return 'vi-VN';
      case 'CN':
      case 'ZH':
        return 'zh-CN';
      case 'ENG':
      case 'EN':
      default:
        return 'en-US';
    }
  }

  /// Speak text in the given language
  static Future<void> speak(String text, String langCode) async {
    final cleanText = text.replaceAll(RegExp(r'Pinyin:[\s\S]*'), '').trim();
    if (cleanText.isEmpty) return;

    // If already speaking this text, stop it
    if (isSpeaking.value && _currentSpeakingText == cleanText) {
      await stop();
      return;
    }

    await initialize();

    final locale = _resolveLocale(langCode);
    _currentSpeakingText = cleanText;

    try {
      await _flutterTts.setLanguage(locale);
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('TTS speak failed: $e, attempting fallback voice command');
      // Fallback via PowerShell on Windows if native TTS plugin fails
      if (Platform.isWindows) {
        _speakViaWindowsPowerShell(cleanText);
      }
    }
  }

  /// Stop any ongoing speech
  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    isSpeaking.value = false;
    _currentSpeakingText = null;
  }

  /// Lightweight fallback using Windows SpVoice via VBS/PowerShell
  static void _speakViaWindowsPowerShell(String text) {
    try {
      final sanitized = text.replaceAll('"', '""').replaceAll("'", "''");
      Process.run('mshta', [
        'vbscript:Execute("CreateObject(""SAPI.SpVoice"").Speak(""$sanitized"")(window.close)")'
      ]);
    } catch (_) {}
  }
}
