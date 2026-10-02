import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/app_toast.dart';
import '../modules/app_config.dart';
import '../modules/llama_service.dart';
import '../modules/local_translation_service.dart';
import '../modules/gguf_translation_service.dart';
import '../modules/model_download_controller.dart';
import '../modules/api_client.dart';

class AiEngineStudioView extends StatefulWidget {
  const AiEngineStudioView({super.key});

  @override
  State<AiEngineStudioView> createState() => _AiEngineStudioViewState();
}

class _AiEngineStudioViewState extends State<AiEngineStudioView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  LanguageProvider get _lang => context.read<LanguageProvider>();
  final _download = ModelDownloadController.instance;
  String? get _downloadingModel => _download.fileName;
  double? get _downloadProgress => _download.progress;

  int _studioTab = 0; // 0: Local AI, 1: Cloud AI, 2: Proxy

  // Local AI State
  bool _isLocalServerRunning = false;
  List<String> _installedModels = [];
  String _selectedLocalModel = '';
  bool _isStartingLocal = false;

  // Cloud AI State
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  bool _obscureApiKey = true;
  String _cloudProvider = 'NVIDIA';
  bool _isTestingCloud = false;

  // Proxy State
  bool _proxyEnabled = false;
  late final TextEditingController _proxyHostController;
  late final TextEditingController _proxyPortController;
  late final TextEditingController _proxyUserController;
  late final TextEditingController _proxyPassController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
      text: AppConfig.get('NVIDIA', 'api_key'),
    );
    _modelController = TextEditingController(
      text: AppConfig.get('NVIDIA', 'model',
          defaultValue: 'meta/llama-3.1-70b-instruct'),
    );

    _proxyEnabled = AppConfig.get('PROXY', 'enabled') == 'true';
    _proxyHostController =
        TextEditingController(text: AppConfig.get('PROXY', 'host'));
    _proxyPortController =
        TextEditingController(text: AppConfig.get('PROXY', 'port'));
    _proxyUserController =
        TextEditingController(text: AppConfig.get('PROXY', 'user'));
    _proxyPassController =
        TextEditingController(text: AppConfig.get('PROXY', 'pass'));

    _download.addListener(_onDownloadChanged);
    LocalTranslationService.instance.addListener(_onNativeChanged);
    GgufTranslationService.instance.addListener(_onNativeChanged);
    _installedModels = LlamaService.getInstalledGgufModels();
    _selectedLocalModel = _installedModels.contains(AppConfig.localGgufModel)
        ? AppConfig.localGgufModel
        : (_installedModels.isNotEmpty ? _installedModels.first : '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadLocalAiStatus();
    });
  }

  @override
  void dispose() {
    _download.removeListener(_onDownloadChanged);
    LocalTranslationService.instance.removeListener(_onNativeChanged);
    GgufTranslationService.instance.removeListener(_onNativeChanged);
    _apiKeyController.dispose();
    _modelController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxyUserController.dispose();
    _proxyPassController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalAiStatus() async {
    await LocalTranslationService.reconcileConfiguration();
    if (['opus_mt', 'gguf_native'].contains(AppConfig.localEngine)) {
      if (mounted) setState(() {});
      return;
    }
    await LlamaService.reconcileLocalConfiguration();
    final running =
        await LlamaService.isServerRunning(port: AppConfig.localLlamaPort);
    final models = await ApiClient.getInstalledLocalModels();
    final currentModel = AppConfig.localGgufModel;

    if (mounted) {
      setState(() {
        _isLocalServerRunning = running;
        _installedModels = models;
        _selectedLocalModel = models.contains(currentModel)
            ? currentModel
            : (models.isNotEmpty ? models.first : '');
      });
    }
  }

  void _openModelsFolder() {
    final dir = LlamaService.getModelsDirectory();
    if (Platform.isWindows) {
      Process.run('explorer.exe', [dir]);
    }
  }

  void _onDownloadChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_download.isDownloading) {
      _loadLocalAiStatus();
      showAppToast(context,
          message: _download.error == null
              ? _lang.tr('ai_download_success')
              : '${_lang.tr('ai_download_error')}: ${_download.error}',
          icon: _download.error == null
              ? Icons.check_circle_rounded
              : Icons.error_outline_rounded,
          accentColor: _download.error == null
              ? context.read<ThemeProvider>().colors.accentEmerald
              : context.read<ThemeProvider>().colors.accentRose);
    }
  }

  Future<void> _downloadModel(LlamaModelPreset preset) =>
      _download.start(preset);

  Future<void> _toggleLocalServer() async {
    final theme = context.read<ThemeProvider>();
    final colors = theme.colors;

    if (_isLocalServerRunning) {
      await LlamaService().stopServer();
      setState(() => _isLocalServerRunning = false);
      if (mounted) {
        showAppToast(
          context,
          message: _lang.tr('ai_studio_3'),
          icon: Icons.stop_circle_outlined,
          accentColor: colors.accentRose,
        );
      }
    } else {
      if (_selectedLocalModel.isEmpty) {
        showAppToast(
          context,
          message: _lang.tr('ai_studio_4'),
          icon: Icons.warning_amber_rounded,
          accentColor: colors.accentAmber,
        );
        return;
      }

      setState(() => _isStartingLocal = true);
      final ok = await LlamaService().startServer(
          modelFileName: _selectedLocalModel,
          port: AppConfig.localLlamaPort,
          threads: AppConfig.localThreads);
      if (ok) await AppConfig.setActiveProvider('local');
      if (mounted) {
        setState(() {
          _isStartingLocal = false;
          _isLocalServerRunning = ok;
        });
        showAppToast(
          context,
          message: ok
              ? _lang
                  .tr('ai_studio_5')
                  .replaceAll('8080', '${AppConfig.localLlamaPort}')
              : '${_lang.tr('ai_studio_6')} ${LlamaService().lastStartError ?? ''}',
          icon: ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          accentColor: ok ? colors.accentEmerald : colors.accentRose,
        );
      }
    }
  }

  Future<void> _saveCloudAiConfig() async {
    AppConfig.set('NVIDIA', 'api_key', _apiKeyController.text.trim());
    AppConfig.set('NVIDIA', 'model', _modelController.text.trim());
    showAppToast(
      context,
      message: _lang.tr('ai_studio_7'),
      icon: Icons.check_rounded,
      accentColor: context.read<ThemeProvider>().colors.accentEmerald,
    );
  }

  Future<void> _testCloudAi() async {
    setState(() => _isTestingCloud = true);
    await _saveCloudAiConfig();

    try {
      final stream = ApiClient.translateStream(
        text: 'Hello world',
        sourceLang: 'en',
        targetLang: 'vi',
        imagePaths: [],
      );
      String result = '';
      await for (final chunk in stream.take(5)) {
        result += chunk;
      }

      if (mounted) {
        setState(() => _isTestingCloud = false);
        final isSuccess = result.isNotEmpty &&
            !result.contains('401') &&
            !result.contains('Unauthorized');
        showAppToast(
          context,
          message:
              isSuccess ? _lang.tr('ai_studio_8') : _lang.tr('ai_studio_9'),
          icon: isSuccess
              ? Icons.check_circle_rounded
              : Icons.error_outline_rounded,
          accentColor: isSuccess
              ? context.read<ThemeProvider>().colors.accentEmerald
              : context.read<ThemeProvider>().colors.accentRose,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTestingCloud = false);
        showAppToast(
          context,
          message: _lang.tr('ai_studio_10').replaceAll('{error}', e.toString()),
          icon: Icons.error_outline_rounded,
          accentColor: context.read<ThemeProvider>().colors.accentRose,
        );
      }
    }
  }

  void _saveProxyConfig() {
    AppConfig.set('PROXY', 'enabled', _proxyEnabled ? 'true' : 'false');
    AppConfig.set('PROXY', 'host', _proxyHostController.text.trim());
    AppConfig.set('PROXY', 'port', _proxyPortController.text.trim());
    AppConfig.set('PROXY', 'user', _proxyUserController.text.trim());
    AppConfig.set('PROXY', 'pass', _proxyPassController.text.trim());

    showAppToast(
      context,
      message: _lang.tr('ai_studio_11'),
      icon: Icons.check_rounded,
      accentColor: context.read<ThemeProvider>().colors.accentEmerald,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final colors = theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Selector Header
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.subCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.subCardBorder),
          ),
          child: Row(
            children: [
              _buildTabBtn(
                  0, Icons.memory_rounded, _lang.tr('ai_studio_0'), colors),
              _buildTabBtn(1, Icons.cloud_queue_rounded,
                  _lang.tr('ai_studio_1'), colors),
              _buildTabBtn(
                  2, Icons.language_rounded, _lang.tr('ai_studio_2'), colors),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Tab Content
        Expanded(
          child: SingleChildScrollView(
            child: _studioTab == 0
                ? _buildLocalAiTab(colors, lang)
                : (_studioTab == 1
                    ? _buildCloudAiTab(colors, lang)
                    : _buildProxyTab(colors, lang)),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBtn(
      int index, IconData icon, String label, AppColors colors) {
    final isSelected = _studioTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _studioTab = index),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [colors.accentColor, colors.accentCyan],
                  )
                : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.white : colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNativeChanged() {
    if (mounted) setState(() {});
  }

  bool get _useGguf => AppConfig.localEngine == 'gguf_native';

  Future<void> _selectQwenModel(String model) async {
    if (_isStartingLocal) return;
    setState(() => _isStartingLocal = true);
    try {
      await GgufTranslationService.instance.unload();
      await AppConfig.set('LOCAL_AI', 'gguf_model', model);
      await AppConfig.set('LOCAL_AI', 'model', model);
      await AppConfig.setActiveProvider('local');
    } catch (error) {
      if (mounted) {
        showAppToast(context,
            message: '${_lang.tr('ai_native_error')}: $error');
      }
    } finally {
      if (mounted) setState(() => _isStartingLocal = false);
    }
  }

  Future<void> _toggleNative() async {
    setState(() => _isStartingLocal = true);
    try {
      if (_useGguf) {
        final engine = GgufTranslationService.instance;
        if (engine.isLoaded) {
          await engine.unload();
        } else {
          await engine.load();
          await AppConfig.setActiveProvider('local');
        }
      } else {
        final engine = LocalTranslationService.instance;
        if (engine.isLoaded) {
          await engine.unload();
        } else {
          final pairs = LocalTranslationService.installedPairs;
          if (pairs.isEmpty) {
            throw StateError(_lang.tr('engine_missing_translation_pack'));
          }
          await engine.load(pairs.first);
          await AppConfig.setActiveProvider('local');
        }
      }
    } catch (error) {
      if (mounted) {
        showAppToast(context,
            message: '${_lang.tr('ai_native_error')}: $error');
      }
    } finally {
      if (mounted) setState(() => _isStartingLocal = false);
    }
  }

  Widget _buildNativeTab(AppColors colors, LanguageProvider lang) {
    final engine = LocalTranslationService.instance;
    final pairs = LocalTranslationService.installedPairs;
    final ggufFile = File(GgufTranslationService.modelPath);
    final loaded =
        _useGguf ? GgufTranslationService.instance.isLoaded : engine.isLoaded;
    final available = _useGguf
        ? GgufTranslationService.isAvailable && ggufFile.existsSync()
        : LocalTranslationService.isAvailable && pairs.isNotEmpty;
    final fileSizeMiB = ggufFile.existsSync()
        ? (ggufFile.lengthSync() / 1024 / 1024).toStringAsFixed(1)
        : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Engine Control & Model Selection Bento Card
        BentoCard(
          colors: colors,
          padding: const EdgeInsets.all(22),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Status Badge & Identity
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          (loaded ? colors.accentEmerald : colors.accentColor)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (loaded ? colors.accentEmerald : colors.accentColor)
                                .withValues(alpha: 0.35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      loaded
                          ? Icons.memory_rounded
                          : Icons.developer_board_rounded,
                      color: loaded ? colors.accentEmerald : colors.accentCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _useGguf
                                  ? 'Qwen GGUF · CPU'
                                  : 'OPUS-MT · INT8 · CPU',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            PillBadge(
                              label: loaded
                                  ? lang.tr('ai_status_active_ram')
                                  : lang.tr('ai_status_standby'),
                              color: loaded
                                  ? colors.accentEmerald
                                  : colors.textMuted,
                              bg: (loaded
                                      ? colors.accentEmerald
                                      : colors.textMuted)
                                  .withValues(alpha: 0.14),
                              border: (loaded
                                      ? colors.accentEmerald
                                      : colors.textMuted)
                                  .withValues(alpha: 0.3),
                              showDot: loaded,
                              fontSize: 10,
                            ),
                            if (AppConfig.isLocalAi) ...[
                              const SizedBox(width: 6),
                              PillBadge(
                                label: lang.tr('ai_status_primary_engine'),
                                color: colors.accentCyan,
                                bg: colors.accentCyan.withValues(alpha: 0.14),
                                border:
                                    colors.accentCyan.withValues(alpha: 0.3),
                                fontSize: 10,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.tr(_useGguf
                              ? 'ai_gguf_description'
                              : 'ai_native_description'),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Dropdown Selection for GGUF Model with Clear Styled Container
              if (_useGguf) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.subCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.subCardBorder),
                  ),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('qwen-model-${AppConfig.localGgufModel}'),
                    initialValue: LlamaService.getInstalledGgufModels()
                            .where((model) =>
                                model.toLowerCase().startsWith('qwen'))
                            .contains(AppConfig.localGgufModel)
                        ? AppConfig.localGgufModel
                        : null,
                    isExpanded: true,
                    dropdownColor: colors.cardHoverBg,
                    decoration: InputDecoration(
                      labelText: lang.tr('ai_engine_gguf'),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    items: LlamaService.getInstalledGgufModels()
                        .where(
                            (model) => model.toLowerCase().startsWith('qwen'))
                        .map((model) => DropdownMenuItem(
                              value: model,
                              child: Text(
                                '$model · $fileSizeMiB MiB',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: _isStartingLocal
                        ? null
                        : (value) {
                            if (value != null) _selectQwenModel(value);
                          },
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Action Buttons Row with High Contrast Accents
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Preload / Free Memory Toggle Button
                  ElevatedButton.icon(
                    onPressed:
                        _isStartingLocal || !available ? null : _toggleNative,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          loaded ? colors.accentRose : colors.accentEmerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isStartingLocal
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            loaded
                                ? Icons.stop_circle_outlined
                                : Icons.bolt_rounded,
                            size: 18,
                          ),
                    label: Text(
                      lang.tr(loaded ? 'ai_native_unload' : 'ai_native_load'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),

                  // Open Models Folder Button
                  OutlinedButton.icon(
                    onPressed: () {
                      if (Platform.isWindows) {
                        Process.run('explorer.exe', [
                          _useGguf
                              ? ggufFile.parent.path
                              : LocalTranslationService.modelsDirectory
                        ]);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.borderDefault),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.folder_open_rounded,
                        size: 18, color: colors.accentCyan),
                    label: Text(
                      lang.tr('ai_native_folder'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),

                  // Activate Local AI Button (if currently on Cloud)
                  if (!AppConfig.isLocalAi)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await AppConfig.setActiveProvider('local');
                        if (mounted) {
                          setState(() {});
                          showAppToast(
                            context,
                            message: lang.tr('ai_set_primary_toast'),
                            icon: Icons.check_circle_rounded,
                            accentColor: colors.accentEmerald,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 17),
                      label: Text(
                        lang.tr('ai_set_primary_btn'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                lang.tr(_useGguf ? 'ai_gguf_limit' : 'ai_native_pivot'),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card 2: Hardware Architecture & Resource Bento Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 680;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isNarrow ? 1 : 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isNarrow ? 3.4 : 1.7,
              children: [
                _buildNativeMetricCard(
                  colors: colors,
                  icon: Icons.speed_rounded,
                  iconColor: colors.accentCyan,
                  title: lang.tr('ai_hw_compute_title'),
                  value: 'CPU · 4 Threads',
                  subtitle: lang.tr('ai_hw_compute_desc'),
                ),
                _buildNativeMetricCard(
                  colors: colors,
                  icon: Icons.pie_chart_rounded,
                  iconColor: colors.accentPurple,
                  title: lang.tr('ai_res_ram_title'),
                  value: '$fileSizeMiB MiB',
                  subtitle: loaded
                      ? lang.tr('ai_res_ram_occupied')
                      : lang.tr('ai_res_ram_idle'),
                ),
                _buildNativeMetricCard(
                  colors: colors,
                  icon: Icons.text_snippet_rounded,
                  iconColor: colors.accentAmber,
                  title: lang.tr('ai_context_title'),
                  value: '4,096 Tokens',
                  subtitle: lang.tr('ai_context_hint'),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        // Card 3: Cloud AI Quick Bridge Banner
        BentoCard(
          colors: colors,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          borderRadius: 14,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cloud_queue_rounded,
                    color: colors.accentCyan, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.tr('ai_cloud_bridge_title'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lang.tr('ai_cloud_bridge_desc'),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _studioTab = 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentCyan,
                  side: BorderSide(
                      color: colors.accentCyan.withValues(alpha: 0.4)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: Text(lang.tr('ai_cloud_bridge_btn'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNativeMetricCard({
    required AppColors colors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLocalAiTab(AppColors colors, LanguageProvider lang) {
    if (['opus_mt', 'gguf_native'].contains(AppConfig.localEngine)) {
      return _buildNativeTab(colors, lang);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status & Control Bento Card
        BentoCard(
          colors: colors,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_isLocalServerRunning
                                  ? colors.accentEmerald
                                  : colors.accentRose)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isLocalServerRunning
                              ? Icons.power_rounded
                              : Icons.power_off_rounded,
                          color: _isLocalServerRunning
                              ? colors.accentEmerald
                              : colors.accentRose,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _lang.tr('ai_studio_12'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              PillBadge(
                                label: _isLocalServerRunning
                                    ? _lang.tr('ai_studio_13').replaceAll(
                                        '8080', '${AppConfig.localLlamaPort}')
                                    : _lang.tr('ai_studio_14'),
                                color: _isLocalServerRunning
                                    ? colors.accentEmerald
                                    : colors.accentRose,
                                bg: (_isLocalServerRunning
                                        ? colors.accentEmerald
                                        : colors.accentRose)
                                    .withValues(alpha: 0.15),
                                border: (_isLocalServerRunning
                                        ? colors.accentEmerald
                                        : colors.accentRose)
                                    .withValues(alpha: 0.4),
                                showDot: true,
                                fontSize: 9.5,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLocalServerRunning
                                ? _lang.tr('ai_studio_15').replaceAll(
                                    '8080', '${AppConfig.localLlamaPort}')
                                : _lang.tr('ai_studio_16'),
                            style: TextStyle(
                                fontSize: 11, color: colors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _openModelsFolder,
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: Text(_lang.tr('ai_studio_17')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.borderDefault),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _isStartingLocal ? null : _toggleLocalServer,
                        icon: _isStartingLocal
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Icon(
                                _isLocalServerRunning
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                size: 18,
                              ),
                        label: Text(_isLocalServerRunning
                            ? _lang.tr('ai_studio_18')
                            : _lang.tr('ai_studio_19')),
                        style: FilledButton.styleFrom(
                          backgroundColor: _isLocalServerRunning
                              ? colors.accentRose
                              : colors.accentEmerald,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Model Selector
              Text(
                _lang.tr('ai_studio_20'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_installedModels.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.accentAmber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: colors.accentAmber, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _lang.tr('ai_studio_21'),
                          style: TextStyle(
                              fontSize: 12, color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _installedModels.map((m) {
                    final isSel = _selectedLocalModel == m;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedLocalModel = m);
                        AppConfig.set('LOCAL_AI', 'model', m);
                        AppConfig.set('LOCAL_AI', 'gguf_model', m);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? colors.accentColor.withValues(alpha: 0.2)
                              : colors.subCardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? colors.accentColor
                                : colors.subCardBorder,
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.description_rounded,
                                size: 14,
                                color: isSel
                                    ? colors.accentCyan
                                    : colors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              m,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight:
                                    isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel
                                    ? colors.accentCyan
                                    : colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Model Presets Bento Card
        BentoCard(
          colors: colors,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _lang.tr('ai_studio_22'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...LlamaService.presets.map((preset) {
                final isInstalled = _installedModels.contains(preset.fileName);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.subCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.subCardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: colors.accentAmber, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  lang.tr(
                                      'ai_preset_name_${LlamaService.presets.indexOf(preset)}'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PillBadge(
                                  label: preset.sizeLabel,
                                  color: colors.accentCyan,
                                  bg: colors.accentCyan.withValues(alpha: 0.15),
                                  border:
                                      colors.accentCyan.withValues(alpha: 0.35),
                                  fontSize: 9.5,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lang.tr(
                                  'ai_preset_desc_${LlamaService.presets.indexOf(preset)}'),
                              style: TextStyle(
                                  fontSize: 11, color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (_downloadingModel == preset.fileName)
                        SizedBox(
                            width: 210,
                            child: Column(children: [
                              LinearProgressIndicator(value: _downloadProgress),
                              const SizedBox(height: 4),
                              Text(
                                  '${ModelDownloadController.formatBytes(_download.receivedBytes)} / '
                                  '${_download.totalBytes > 0 ? ModelDownloadController.formatBytes(_download.totalBytes) : lang.tr('ai_unknown_size')}',
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11)),
                              Text(
                                  '${ModelDownloadController.formatBytes(_download.bytesPerSecond)}/s',
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11)),
                              Text(
                                  _downloadProgress == null
                                      ? lang.tr('ai_downloading')
                                      : '${(_downloadProgress! * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11)),
                            ]))
                      else if (isInstalled)
                        PillBadge(
                          label: _lang.tr('ai_studio_23'),
                          color: colors.accentEmerald,
                          bg: colors.accentEmerald.withValues(alpha: 0.15),
                          border: colors.accentEmerald.withValues(alpha: 0.4),
                          fontSize: 10,
                          icon: Icons.check_circle_rounded,
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _downloadingModel != null
                              ? null
                              : () => _downloadModel(preset),
                          icon: const Icon(Icons.download_rounded, size: 14),
                          label: Text(_lang.tr('ai_studio_24')),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloudAiTab(AppColors colors, LanguageProvider lang) {
    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _lang.tr('ai_studio_25'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lang.tr('ai_studio_26'),
            style: TextStyle(fontSize: 11.5, color: colors.textMuted),
          ),
          const SizedBox(height: 16),

          // Provider selector
          Wrap(
            spacing: 8,
            children: ['NVIDIA', 'OpenAI', 'Groq', 'OpenRouter'].map((p) {
              final isSel = _cloudProvider == p;
              return ChoiceChip(
                label: Text(p),
                selected: isSel,
                selectedColor: colors.accentColor.withValues(alpha: 0.25),
                backgroundColor: colors.subCardBg,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? colors.accentCyan : colors.textSecondary,
                ),
                onSelected: (val) {
                  if (val) setState(() => _cloudProvider = p);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // API Key field
          Text(
            'API Key ($_cloudProvider):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: _lang.tr('ai_studio_27'),
              hintStyle: TextStyle(fontSize: 11.5, color: colors.textMuted),
              filled: true,
              fillColor: colors.subCardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.subCardBorder),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: colors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Model Name field
          Text(
            _lang.tr('ai_studio_28'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _modelController,
            style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'meta/llama-3.1-70b-instruct',
              hintStyle: TextStyle(fontSize: 11.5, color: colors.textMuted),
              filled: true,
              fillColor: colors.subCardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.subCardBorder),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          const SizedBox(height: 20),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _isTestingCloud ? null : _testCloudAi,
                icon: _isTestingCloud
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt_rounded, size: 16),
                label: Text(_lang.tr('ai_studio_29')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentCyan,
                  side: BorderSide(color: colors.accentCyan),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _saveCloudAiConfig,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: Text(_lang.tr('ai_studio_30')),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProxyTab(AppColors colors, LanguageProvider lang) {
    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lang.tr('ai_studio_31'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _lang.tr('ai_studio_32'),
                    style: TextStyle(fontSize: 11.5, color: colors.textMuted),
                  ),
                ],
              ),
              Switch(
                value: _proxyEnabled,
                activeColor: colors.accentEmerald,
                onChanged: (val) => setState(() => _proxyEnabled = val),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_lang.tr('ai_studio_33'),
                        style:
                            TextStyle(fontSize: 12, color: colors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _proxyHostController,
                      style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _lang.tr('ai_studio_34'),
                        filled: true,
                        fillColor: colors.subCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.subCardBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_lang.tr('ai_studio_35'),
                        style:
                            TextStyle(fontSize: 12, color: colors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _proxyPortController,
                      style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '8080',
                        filled: true,
                        fillColor: colors.subCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.subCardBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_lang.tr('ai_studio_36'),
                        style:
                            TextStyle(fontSize: 12, color: colors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _proxyUserController,
                      style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.subCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.subCardBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_lang.tr('ai_studio_37'),
                        style:
                            TextStyle(fontSize: 12, color: colors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _proxyPassController,
                      obscureText: true,
                      style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.subCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.subCardBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: _saveProxyConfig,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: Text(_lang.tr('ai_studio_38')),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
