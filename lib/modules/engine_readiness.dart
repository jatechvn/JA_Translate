import 'app_config.dart';
import 'llama_service.dart';
import 'local_translation_service.dart';
import 'gguf_translation_service.dart';
import 'dart:io';

/// Configuration prerequisites; this does not claim remote connectivity.
class EngineReadiness {
  static String evaluate(
      {required bool isLocal,
      required String apiKey,
      required String cloudModel,
      required String apiBase,
      required String localModel,
      required List<String> installedModels,
      required bool hasLocalServer}) {
    if (isLocal) {
      if (!installedModels.contains(localModel)) {
        return 'engine_missing_local_model';
      }
      if (!hasLocalServer) return 'engine_missing_local_server';
    } else {
      final uri = Uri.tryParse(apiBase.trim());
      if (apiKey.trim().isEmpty ||
          cloudModel.trim().isEmpty ||
          uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty) {
        return 'engine_missing_cloud_config';
      }
    }
    return 'engine_configured';
  }

  static String get current => forTranslation();
  static String forTranslation(
      {String? sourceLang, String? targetLang, String text = ''}) {
    if (AppConfig.isLocalAi && AppConfig.localEngine == 'gguf_native') {
      if (!GgufTranslationService.isAvailable) return 'engine_missing_native';
      if (!File(GgufTranslationService.modelPath).existsSync()) {
        return 'engine_missing_local_model';
      }
      return 'engine_configured';
    }
    if (AppConfig.isLocalAi && AppConfig.localEngine == 'opus_mt') {
      if (!LocalTranslationService.isAvailable) return 'engine_missing_native';
      final installed = LocalTranslationService.installedPairs;
      if (installed.isEmpty) return 'engine_missing_translation_pack';
      if (sourceLang != null && targetLang != null && text.trim().isNotEmpty) {
        final source = LocalTranslationService.normalizeLanguage(sourceLang);
        final target = LocalTranslationService.normalizeLanguage(targetLang);
        final route = LocalTranslationService.route(
            source == 'auto'
                ? LocalTranslationService.detectSource(text)
                : source,
            target);
        if (route.any((pair) => !installed.contains(pair))) {
          return 'engine_missing_translation_pack';
        }
      }
      return 'engine_configured';
    }
    return evaluate(
      isLocal: AppConfig.isLocalAi,
      apiKey: AppConfig.get('NVIDIA', 'api_key'),
      cloudModel: AppConfig.get('NVIDIA', 'model'),
      apiBase: AppConfig.get('NVIDIA', 'api_base',
          defaultValue: 'https://integrate.api.nvidia.com/v1'),
      localModel: AppConfig.localGgufModel,
      installedModels: AppConfig.isLocalAi
          ? LlamaService.getInstalledGgufModels()
          : const [],
      hasLocalServer: !AppConfig.isLocalAi ||
          LlamaService.getLlamaServerExecutable() != null,
    );
  }
}
