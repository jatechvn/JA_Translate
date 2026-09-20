// lib/modules/logic.dart
// Core coordinator logic for translation streams and offline Pinyin processing

import 'package:lpinyin/lpinyin.dart';
import 'api_client.dart';
import 'translation_cache.dart';

class TranslateLogic {
  /// Checks if translation is cached locally
  static bool isCached(String text, String sourceLang, String targetLang) {
    return TranslationCache.get(text, sourceLang, targetLang) != null;
  }

  /// Converts Chinese characters to Pinyin with tone marks offline
  static String getPinyinOffline(String text) {
    try {
      // Remove any Pinyin label formatting if present in the text to avoid double-processing
      final targetText = text
          .replaceAll(RegExp(r'^Pinyin:\s*', caseSensitive: false), '')
          .trim();
      return PinyinHelper.getPinyin(targetText,
          separator: ' ', format: PinyinFormat.WITH_TONE_MARK);
    } catch (_) {
      return '';
    }
  }

  /// Routes streaming translation task to the ApiClient
  static Stream<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
    required List<String> imagePaths,
  }) {
    return ApiClient.translateStream(
      text: text,
      sourceLang: sourceLang,
      targetLang: targetLang,
      imagePaths: imagePaths,
    );
  }
}
