// lib/modules/translation_history.dart
// Manage translation history and starred items with local JSON database

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class TranslationRecord {
  final String id;
  final String text;
  final String translated;
  final String srcLang;
  final String tgtLang;
  final DateTime timestamp;
  bool isSaved;

  TranslationRecord({
    required this.id,
    required this.text,
    required this.translated,
    required this.srcLang,
    required this.tgtLang,
    required this.timestamp,
    this.isSaved = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'translated': translated,
        'srcLang': srcLang,
        'tgtLang': tgtLang,
        'timestamp': timestamp.toIso8601String(),
        'isSaved': isSaved,
      };

  factory TranslationRecord.fromJson(Map<String, dynamic> json) =>
      TranslationRecord(
        id: json['id'] as String,
        text: json['text'] as String,
        translated: json['translated'] as String,
        srcLang: json['srcLang'] as String,
        tgtLang: json['tgtLang'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isSaved: json['isSaved'] as bool? ?? false,
      );
}

class TranslationHistory {
  static String? _historyPath;
  static final List<TranslationRecord> records = [];
  static const int maxUnsavedRecords = 100;

  /// Initialize and load translation history from disk.
  static void initialize() {
    try {
      if (kDebugMode) {
        _historyPath = p.join(Directory.current.path, 'translation_history.json');
      } else {
        final exeDir = p.dirname(Platform.resolvedExecutable);
        _historyPath = p.join(exeDir, 'translation_history.json');
      }
      _load();
    } catch (_) {
      _historyPath = 'translation_history.json';
      _load();
    }
  }

  static void _load() {
    if (_historyPath == null) return;
    try {
      final file = File(_historyPath!);
      if (file.existsSync()) {
        final content = file.readAsStringSync(encoding: utf8);
        final list = jsonDecode(content) as List<dynamic>;
        records.clear();
        for (final item in list) {
          records.add(TranslationRecord.fromJson(item as Map<String, dynamic>));
        }
        // Sort: newest first
        records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (_) {}
  }

  /// Write history to disk.
  static Future<void> saveToDisk() async {
    if (_historyPath == null) return;
    try {
      final file = File(_historyPath!);
      final list = records.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(list), encoding: utf8);
    } catch (_) {}
  }

  /// Add a translation entry to history.
  static void addRecord(String text, String translated, String srcLang, String tgtLang, {bool isSaved = false}) {
    if (text.trim().isEmpty || translated.trim().isEmpty) return;
    
    // Check if duplicate exists (same text, languages)
    final existingIdx = records.indexWhere((r) =>
        r.text == text &&
        r.srcLang == srcLang &&
        r.tgtLang == tgtLang);

    if (existingIdx != -1) {
      // Update timestamp and optionally isSaved flag, then move to top
      final existing = records.removeAt(existingIdx);
      final updated = TranslationRecord(
        id: existing.id,
        text: existing.text,
        translated: existing.translated,
        srcLang: existing.srcLang,
        tgtLang: existing.tgtLang,
        timestamp: DateTime.now(),
        isSaved: isSaved || existing.isSaved,
      );
      records.insert(0, updated);
    } else {
      // Add new record at the top
      final newRecord = TranslationRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        translated: translated,
        srcLang: srcLang,
        tgtLang: tgtLang,
        timestamp: DateTime.now(),
        isSaved: isSaved,
      );
      records.insert(0, newRecord);
    }

    _housekeep();
    saveToDisk();
  }

  /// Evict older unsaved history records once count exceeds maxUnsavedRecords.
  static void _housekeep() {
    int unsavedCount = 0;
    final List<TranslationRecord> toKeep = [];

    for (final r in records) {
      if (r.isSaved) {
        toKeep.add(r);
      } else {
        if (unsavedCount < maxUnsavedRecords) {
          toKeep.add(r);
          unsavedCount++;
        }
      }
    }

    records.clear();
    records.addAll(toKeep);
  }

  /// Check if a translation is marked as saved.
  static bool isSaved(String text, String translated, String srcLang, String tgtLang) {
    return records.any((r) =>
        r.text == text &&
        r.translated == translated &&
        r.srcLang == srcLang &&
        r.tgtLang == tgtLang &&
        r.isSaved);
  }

  /// Toggle save status of a record by ID.
  static void toggleSave(String id) {
    final idx = records.indexWhere((r) => r.id == id);
    if (idx != -1) {
      records[idx].isSaved = !records[idx].isSaved;
      saveToDisk();
    }
  }

  /// Toggle save status of a translation directly.
  static void toggleSaveForTranslation(String text, String translated, String srcLang, String tgtLang) {
    final idx = records.indexWhere((r) =>
        r.text == text &&
        r.translated == translated &&
        r.srcLang == srcLang &&
        r.tgtLang == tgtLang);

    if (idx != -1) {
      records[idx].isSaved = !records[idx].isSaved;
    } else {
      // If it doesn't exist in history, add it as saved
      addRecord(text, translated, srcLang, tgtLang, isSaved: true);
    }
    saveToDisk();
  }

  /// Delete a record by ID.
  static void deleteRecord(String id) {
    records.removeWhere((r) => r.id == id);
    saveToDisk();
  }

  /// Clear all unsaved records from history.
  static void clearHistory() {
    records.removeWhere((r) => !r.isSaved);
    saveToDisk();
  }
}
