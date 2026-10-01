import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ja_translate/modules/app_config.dart';
import 'package:ja_translate/modules/llama_service.dart';
import 'package:ja_translate/modules/local_translation_service.dart';
import 'package:ja_translate/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Previous OPUS default migrates once to native Qwen', () async {
    await AppConfig.set('LOCAL_AI', 'qwen_native_migration', '');
    await AppConfig.set('LOCAL_AI', 'engine', 'opus_mt');
    await LocalTranslationService.reconcileConfiguration();
    expect(AppConfig.localEngine, 'gguf_native');
    expect(AppConfig.get('LOCAL_AI', 'qwen_native_migration'), '1');
  });

  test('Startup preserves explicitly selected embedded GGUF engine', () async {
    final previous = AppConfig.localEngine;
    await AppConfig.set('LOCAL_AI', 'engine', 'gguf_native');
    await LocalTranslationService.reconcileConfiguration();
    expect(AppConfig.localEngine, 'gguf_native');
    await AppConfig.set('LOCAL_AI', 'engine', previous);
  });

  test(
      'Unconfigured cloud yields to installed Local; preserves configured Cloud',
      () async {
    await AppConfig.setActiveProvider('cloud');
    await AppConfig.set('NVIDIA', 'api_key', '');
    await AppConfig.set('LOCAL_AI', 'gguf_model', 'missing.gguf');
    await AppConfig.set('LOCAL_AI', 'model', 'installed.gguf');
    await AppConfig.reconcileAvailableModels(['installed.gguf', 'mmproj.gguf']);
    expect(AppConfig.isLocalAi, isTrue);
    expect(AppConfig.localGgufModel, 'installed.gguf');
    await AppConfig.set('NVIDIA', 'api_key', 'test-key');
    await AppConfig.setActiveProvider('cloud');
    await AppConfig.reconcileAvailableModels(['installed.gguf']);
    expect(AppConfig.isLocalAi, isFalse);
    await AppConfig.set('NVIDIA', 'api_key', '');
    await AppConfig.reconcileAvailableModels([]);
    expect(AppConfig.isLocalAi, isFalse);
  });

  test('Local launch paths are absolute before workingDirectory changes', () {
    expect(p.isAbsolute(LlamaService.getModelsDirectory()), isTrue);
    final executable = LlamaService.getLlamaServerExecutable();
    expect(executable, isNotNull);
    expect(p.isAbsolute(executable!), isTrue);
    expect(File(executable).existsSync(), isTrue);
    expect(Directory(LlamaService.getModelsDirectory()).existsSync(), isTrue);
  }, skip: !Platform.isWindows);

  testWidgets(
      'Successful native theme sync does not overwrite composition via acrylic plugin',
      (tester) async {
    var nativeCalls = 0;
    var pluginCalls = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('ja_translate/theme'), (call) async {
      nativeCalls++;
      return true;
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('com.alexmercerind/flutter_acrylic'), (call) async {
      pluginCalls++;
      return null;
    });
    await Window.initialize();
    pluginCalls = 0;
    AppConfig.enableTransparency = true;
    final theme = ThemeProvider(initialMode: 'dark');
    await tester.pump();
    theme.setThemeMode('light');
    await tester.pump();
    expect(nativeCalls, 2);
    expect(pluginCalls, 0);
    theme.dispose();
    messenger.setMockMethodCallHandler(
        const MethodChannel('ja_translate/theme'), null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('com.alexmercerind/flutter_acrylic'), null);
  }, skip: !Platform.isWindows);
}
