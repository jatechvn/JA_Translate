// lib/modules/translation_cache.dart
// Lightweight, zero-dependency translation cache manager utilizing a local JSON database

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class TranslationCache {
  static String? _cachePath;
  static final Map<String, String> _cache = {};

  static String? get cachePath {
    if (_cachePath == null) initialize();
    return _cachePath;
  }

  /// Initialize and load translation cache from disk.
  static void initialize() {
    try {
      if (kDebugMode) {
        _cachePath = p.join(Directory.current.path, 'translation_cache.json');
      } else {
        final exeDir = p.dirname(Platform.resolvedExecutable);
        _cachePath = p.join(exeDir, 'translation_cache.json');
      }
      _load();
    } catch (_) {
      _cachePath = 'translation_cache.json';
      _load();
    }
  }

  static void _load() {
    if (_cachePath == null) return;
    try {
      final file = File(_cachePath!);
      if (file.existsSync()) {
        final content = file.readAsStringSync(encoding: utf8);
        final data = jsonDecode(content) as Map<String, dynamic>;
        data.forEach((key, value) {
          _cache[key] = value.toString();
        });
      }
    } catch (_) {}
  }

  /// Retrieve cached translation for the specified text and language pair
  static String? get(String text, String srcLang, String tgtLang) {
    if (_cache.isEmpty) initialize();
    final key = '$srcLang->$tgtLang:$text';
    return _cache[key];
  }

  /// Write a new translation to the cache on disk
  static Future<void> set(
      String text, String srcLang, String tgtLang, String translated) async {
    if (_cachePath == null) initialize();
    final key = '$srcLang->$tgtLang:$text';
    _cache[key] = translated;

    try {
      final file = File(_cachePath!);
      await file.writeAsString(jsonEncode(_cache), encoding: utf8);
    } catch (_) {}
  }
}
