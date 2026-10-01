import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ja_translate/modules/app_config.dart';
import 'package:ja_translate/modules/document_translator.dart';
import 'package:ja_translate/modules/local_translation_service.dart';
import 'package:ja_translate/modules/gguf_translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('DOCX helper uses the app native engine without AI HTTP', () async {
    final project = Directory.current.path;
    final ggufModel = GgufTranslationService.modelPath;
    final fixture = Directory(p.join(project, '.local_ai_tools',
        'doc-native-smoke-${DateTime.now().microsecondsSinceEpoch}'));
    fixture.createSync(recursive: true);
    void copyTree(String source, String target) {
      Directory(target).createSync(recursive: true);
      for (final entry in Directory(source).listSync()) {
        final destination = p.join(target, p.basename(entry.path));
        if (entry is Directory) {
          copyTree(entry.path, destination);
        } else if (entry is File) {
          entry.copySync(destination);
        }
      }
    }

    copyTree(p.join(project, 'native/runtime'),
        p.join(fixture.path, 'native/runtime'));
    copyTree(p.join(project, 'models/opus-mt/en-vi'),
        p.join(fixture.path, 'models/opus-mt/en-vi'));
    Directory(p.join(fixture.path, 'lib/modules')).createSync(recursive: true);
    File(p.join(project, 'lib/modules/document_processor.py'))
        .copySync(p.join(fixture.path, 'lib/modules/document_processor.py'));
    // A deliberately invalid Cloud endpoint proves the helper must use app IPC.
    File(p.join(fixture.path, 'config.ini')).writeAsStringSync(
        '[SETTINGS]\nactive_provider=cloud\n[NVIDIA]\napi_key=\napi_base=http://127.0.0.1:1/v1\nmodel=invalid\n');
    final python = p.join(Platform.environment['LOCALAPPDATA']!,
        'Programs/Python/Python313/python.exe');
    final input = p.join(fixture.path, 'input.docx');
    final prepared = await Process.run(python, [
      '-X',
      'utf8',
      '-c',
      'from docx import Document; import sys; d=Document(); d.add_paragraph("Please check the network connection."); d.save(sys.argv[1])',
      input
    ]);
    expect(prepared.exitCode, 0, reason: prepared.stderr.toString());
    Directory.current = fixture.path;
    try {
      for (final backend in ['opus_mt', 'gguf_native']) {
        await AppConfig.set('LOCAL_AI', 'gguf_model', ggufModel);
        await AppConfig.set('LOCAL_AI', 'engine', backend);
        await AppConfig.setActiveProvider('local');
        final events = await DocumentTranslator.translateDocument(
                filePath: input, sourceLang: 'en', targetLang: 'vi')
            .toList();
        final errors = events.where((event) => event.error != null).toList();
        expect(errors.map((event) => event.error), isEmpty);
        final completed =
            events.where((event) => event.status == 'complete').single;
        expect(File(completed.resultText!).existsSync(), isTrue);
        final checked = await Process.run(
            python,
            [
              '-X',
              'utf8',
              '-c',
              'from docx import Document; import sys; print("\\n".join(p.text for p in Document(sys.argv[1]).paragraphs))',
              completed.resultText!
            ],
            stdoutEncoding: utf8,
            stderrEncoding: utf8);
        expect(checked.exitCode, 0);
        expect(checked.stdout.toString(), contains('kiểm tra'));
        if (backend == 'opus_mt') {
          await LocalTranslationService.instance.unload();
        } else {
          await GgufTranslationService.instance.unload();
        }
      }
    } finally {
      Directory.current = project;
      // Preserve smoke artifacts under ignored .local_ai_tools for inspection.
    }
  },
      skip:
          !Platform.isWindows || Platform.environment['JA_TEST_NATIVE'] != '1',
      timeout: const Timeout(Duration(minutes: 2)));
}
