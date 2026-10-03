import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/modules/logic.dart';
import 'package:ja_translate/modules/desktop_service.dart';

void main() {
  group('TranslateLogic.cleanChineseForCopy', () {
    test('Cleans standard Pinyin phonetic annotations from Chinese output', () {
      const output = '你好世界\n\nPinyin:\nnǐ hǎo shì jiè';
      final clean = TranslateLogic.cleanChineseForCopy(output);
      expect(clean, '你好世界');
    });

    test('Cleans multiline Chinese text with Pinyin block', () {
      const output = '''
第一行：欢迎来到JA Translate。
第二行：高性能离线与云端翻译。

Pinyin:
dì yī háng ： huān yíng lái dào JA Translate 。
dì èr háng ： gāo xìng néng lí xiàn yǔ yún duān fān yì 。
''';
      final clean = TranslateLogic.cleanChineseForCopy(output);
      expect(clean, contains('第一行：欢迎来到JA Translate。'));
      expect(clean, contains('第二行：高性能离线与云端翻译。'));
      expect(clean.contains('Pinyin:'), isFalse);
      expect(clean.contains('huān yíng'), isFalse);
    });

    test('Preserves text without Pinyin annotations', () {
      const input = 'Xin chào thế giới';
      expect(TranslateLogic.cleanChineseForCopy(input), 'Xin chào thế giới');

      const chineseOnly = '祝你今天过得愉快！';
      expect(TranslateLogic.cleanChineseForCopy(chineseOnly), '祝你今天过得愉快！');

      const englishOnly = 'Hello, this is a test.';
      expect(TranslateLogic.cleanChineseForCopy(englishOnly),
          'Hello, this is a test.');
    });

    test('Handles case-insensitive Pinyin headers and spacing variants', () {
      const lowercase = '谢谢\npinyin: xiè xie';
      expect(TranslateLogic.cleanChineseForCopy(lowercase), '谢谢');

      const uppercase = '再见\n\nPINYIN:\nzài jiàn';
      expect(TranslateLogic.cleanChineseForCopy(uppercase), '再见');

      const spaces = '好的\n   Pinyin:   hǎo de';
      expect(TranslateLogic.cleanChineseForCopy(spaces), '好的');
    });

    test('Handles empty and whitespace strings safely', () {
      expect(TranslateLogic.cleanChineseForCopy(''), '');
      expect(TranslateLogic.cleanChineseForCopy('   '), '   ');
    });
  });

  group('DesktopService Clipboard Image Capabilities', () {
    test('hasClipboardImage API is accessible statically', () {
      // Returns a boolean without throwing exceptions
      final hasImage = DesktopService.hasClipboardImage();
      expect(hasImage, isA<bool>());
    });
  });
}
