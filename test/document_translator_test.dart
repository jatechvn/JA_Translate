// test/document_translator_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/modules/document_translator.dart';

void main() {
  group('DocumentTranslator tests', () {
    late Directory tempDir;
    late File tempTxtFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ja_translate_test');
      tempTxtFile = File('${tempDir.path}/test_doc.txt');
      await tempTxtFile.writeAsString('Hello world.\nThis is a test of document translator.');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('getFileStats returns correct character and word counts for txt files', () async {
      final stats = await DocumentTranslator.getFileStats(tempTxtFile.path);

      expect(stats.charCount, equals(51)); // 'Hello world.\nThis is a test of document translator.'.length
      expect(stats.wordCount, equals(9)); // 9 words
    });
  });
}
