import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/app_toast.dart';
import '../modules/app_config.dart';
import '../modules/engine_readiness.dart';
import '../modules/logic.dart';
import '../modules/tts_service.dart';
import '../modules/stt_service.dart';
import '../modules/desktop_service.dart';
import '../modules/translation_history.dart';

class TextTranslationView extends StatefulWidget {
  const TextTranslationView({super.key});

  @override
  State<TextTranslationView> createState() => TextTranslationViewState();
}

class TextTranslationViewState extends State<TextTranslationView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  String _srcLang = 'auto';
  String _tgtLang = 'vi';
  bool _isLoading = false;
  bool _realtimeEnabled = true;
  bool _showPinyin = true;
  bool _isRecordingVoice = false;

  String _statusText = 'READY';
  Timer? _debounceTimer;
  final List<String> _attachedImages = [];

  void restoreText(String text, String src, String tgt) {
    setState(() {
      _inputController.text = text;
      _srcLang = src;
      _tgtLang = tgt;
    });
    if (text.trim().isNotEmpty) {
      _startTranslation();
    }
  }

  static const List<Map<String, String>> _sourceLanguages = [
    {'code': 'auto', 'labelKey': 'lang_auto'},
    {'code': 'vi', 'labelKey': 'lang_vi'},
    {'code': 'en', 'labelKey': 'lang_en'},
    {'code': 'zh', 'labelKey': 'lang_zh'},
  ];

  static const List<Map<String, String>> _targetLanguages = [
    {'code': 'vi', 'labelKey': 'lang_vi'},
    {'code': 'en', 'labelKey': 'lang_en'},
    {'code': 'zh', 'labelKey': 'lang_zh'},
  ];

  @override
  void initState() {
    super.initState();
    _srcLang = AppConfig.get('SETTINGS', 'source_lang', defaultValue: 'auto');
    _tgtLang = AppConfig.get('SETTINGS', 'target_lang', defaultValue: 'vi');
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
    if (!_realtimeEnabled || _isLoading) return;

    _debounceTimer?.cancel();
    final text = _inputController.text.trim();
    if (text.isEmpty && _attachedImages.isEmpty) {
      _outputController.clear();
      setState(() => _statusText = 'READY');
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _startTranslation();
    });
  }

  void _swapLanguages() {
    if (_srcLang == 'auto') return;
    setState(() {
      final temp = _srcLang;
      _srcLang = _tgtLang;
      _tgtLang = temp;

      final tempText = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = tempText;
    });
    AppConfig.set('SETTINGS', 'source_lang', _srcLang);
    AppConfig.set('SETTINGS', 'target_lang', _tgtLang);
  }

  void _selectSourceLang(String code) {
    setState(() => _srcLang = code);
    AppConfig.set('SETTINGS', 'source_lang', code);
    if (_realtimeEnabled && _inputController.text.trim().isNotEmpty) {
      _startTranslation();
    }
  }

  void _selectTargetLang(String code) {
    setState(() => _tgtLang = code);
    AppConfig.set('SETTINGS', 'target_lang', code);
    if (_realtimeEnabled && _inputController.text.trim().isNotEmpty) {
      _startTranslation();
    }
  }

  Future<void> _startTranslation() async {
    if (_isLoading) return;
    final text = _inputController.text.trim();
    if (text.isEmpty && _attachedImages.isEmpty) return;

    final readiness = EngineReadiness.forTranslation(
        sourceLang: _srcLang,
        targetLang: _tgtLang,
        text: _inputController.text);
    if (readiness != 'engine_configured') {
      if (!mounted) return;
      if (readiness == 'engine_missing_native' ||
          readiness == 'engine_missing_translation_pack') {
        final lang = context.read<LanguageProvider>();
        showAppToast(context,
            message: lang.tr(readiness),
            icon: Icons.warning_amber_rounded,
            accentColor: context.read<ThemeProvider>().colors.accentAmber);
      } else if (AppConfig.isLocalAi) {
        _showMissingLocalModelDialog(
            missingServer: readiness == 'engine_missing_local_server');
      } else {
        _showMissingCloudConfigDialog();
      }
      return;
    }

    _debounceTimer?.cancel();
    final isCached = _attachedImages.isEmpty &&
        TranslateLogic.isCached(text, _srcLang, _tgtLang);

    setState(() {
      _isLoading = true;
      _outputController.clear();
      _statusText = isCached ? 'CACHED' : 'TRANSLATING...';
    });

    try {
      final responseStream = TranslateLogic.translate(
        text: text,
        sourceLang: _srcLang,
        targetLang: _tgtLang,
        imagePaths: _attachedImages,
      );

      await for (final chunk in responseStream) {
        if (!mounted) break;
        if (chunk.contains('Không thể khởi động llama-server local') ||
            chunk.contains('Vui lòng kiểm tra model GGUF') ||
            chunk.contains('Lỗi kết nối Local AI')) {
          _outputController.clear();
          if (mounted) _showMissingLocalModelDialog();
          break;
        }
        if (chunk.contains('status 401') ||
            chunk.contains('Unauthorized') ||
            chunk.contains('status 403') ||
            chunk.contains('API Key Cloud không hợp lệ')) {
          _outputController.clear();
          if (mounted) _showMissingCloudConfigDialog();
          break;
        }
        _outputController.text += chunk;
      }

      // Process offline Pinyin if Chinese characters exist
      final chinesePattern = RegExp(r'[\u4e00-\u9fff]');
      final currentOutput = _outputController.text;
      if (chinesePattern.hasMatch(currentOutput)) {
        final pinyin = TranslateLogic.getPinyinOffline(currentOutput);
        if (pinyin.isNotEmpty && !currentOutput.contains('Pinyin:')) {
          _outputController.text = '$currentOutput\n\nPinyin:\n$pinyin';
        }
      }

      final finalOutput = _outputController.text.trim();
      if (finalOutput.isNotEmpty) {
        TranslationHistory.addRecord(text, finalOutput, _srcLang, _tgtLang);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = isCached ? 'COMPLETE (CACHED)' : 'COMPLETE';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = 'ERROR';
        });
        showAppToast(
          context,
          message:
              '${context.read<LanguageProvider>().tr('translation_error_prefix')}: $e',
          icon: Icons.error_outline_rounded,
          accentColor: context.read<ThemeProvider>().colors.accentRose,
        );
      }
    }
  }

  void _showMissingLocalModelDialog({bool missingServer = false}) {
    final lang = context.read<LanguageProvider>();
    final theme = context.read<ThemeProvider>();
    final colors = theme.colors;
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: lang.tr(missingServer
            ? 'missing_local_server_title'
            : 'missing_local_title'),
        icon: Icons.download_for_offline_rounded,
        isDark: theme.isDark,
        width: 480,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang.tr('settings_btn_close'),
                style: TextStyle(color: colors.textSecondary)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Switch to Cloud AI as temporary fallback
              AppConfig.setActiveProvider('cloud');
              setState(() {});
              _startTranslation();
            },
            icon: const Icon(Icons.cloud_queue_rounded, size: 16),
            label: Text(lang.tr('use_cloud_temporarily')),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.tr(missingServer
                  ? 'missing_local_server_body'
                  : 'missing_local_body'),
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              lang.tr('missing_local_hint'),
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _showMissingCloudConfigDialog() {
    final lang = context.read<LanguageProvider>();
    final theme = context.read<ThemeProvider>();
    final colors = theme.colors;
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: lang.tr('missing_cloud_title'),
        icon: Icons.vpn_key_rounded,
        isDark: theme.isDark,
        width: 480,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang.tr('settings_btn_close'),
                style: TextStyle(color: colors.textSecondary)),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.tr('missing_cloud_body'),
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              lang.tr('missing_cloud_hint'),
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecordingVoice) {
      setState(() {
        _isRecordingVoice = false;
        _statusText = 'TRANSCRIBING AUDIO...';
      });
      final transcribedText =
          await SttService.stopRecordingAndTranscribe(targetLang: _srcLang);
      if (transcribedText != null && transcribedText.isNotEmpty) {
        setState(() {
          _inputController.text = transcribedText;
          _statusText = 'VOICE READY';
        });
        _startTranslation();
      } else {
        setState(() => _statusText = 'VOICE FAILED');
      }
    } else {
      final hasPerm = await SttService.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          showAppToast(
            context,
            message: 'Cần cấp quyền Microphone để ghi âm giọng nói!',
            icon: Icons.mic_off_rounded,
            accentColor: context.read<ThemeProvider>().colors.accentAmber,
          );
        }
        return;
      }
      final started = await SttService.startRecording();
      if (started) {
        setState(() {
          _isRecordingVoice = true;
          _statusText = 'RECORDING...';
        });
      }
    }
  }

  Future<void> _attachImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          _attachedImages.addAll(result.paths.whereType<String>());
          _statusText = 'ATTACHED ${_attachedImages.length} IMAGES';
        });
        _startTranslation();
      }
    } catch (_) {}
  }

  Future<void> _triggerScreenSnip() async {
    setState(() => _statusText = 'SNIPPING SCREEN...');
    final imagePath = await DesktopService.captureScreenSnip();
    if (imagePath != null && mounted) {
      setState(() {
        _attachedImages.add(imagePath);
        _statusText = 'ATTACHED SCREEN SNIP';
      });
      _startTranslation();
    } else if (mounted) {
      setState(() => _statusText = 'SNIP CANCELLED');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final colors = theme.colors;
    final readiness = EngineReadiness.forTranslation(
        sourceLang: _srcLang,
        targetLang: _tgtLang,
        text: _inputController.text);

    final inputChars = _inputController.text.length;
    final inputWords = _inputController.text.trim().isEmpty
        ? 0
        : _inputController.text.trim().split(RegExp(r'\s+')).length;
    final outputChars = _outputController.text.length;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            HardwareKeyboard.instance.isControlPressed) {
          _startTranslation();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Language Selector & Toolbar Header
          _buildLanguageSelectorBar(colors, lang),
          const SizedBox(height: 12),

          // 2. Dual Bento Cards (Input & Output)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Bento: Input
                Expanded(
                  child: BentoCard(
                    colors: colors,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  PillBadge(
                                    label: _getLangName(_srcLang, lang)
                                        .toUpperCase(),
                                    color: colors.accentCyan,
                                    bg: colors.accentCyan
                                        .withValues(alpha: 0.15),
                                    border: colors.accentCyan
                                        .withValues(alpha: 0.4),
                                    icon: Icons.translate_rounded,
                                    fontSize: 10,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      lang.t('char_count',
                                          [inputChars, inputWords]),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Quick Action Tools
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIconButton(
                                  icon: _isRecordingVoice
                                      ? Icons.mic_rounded
                                      : Icons.mic_none_rounded,
                                  color: _isRecordingVoice
                                      ? colors.accentRose
                                      : colors.textSecondary,
                                  tooltip: lang.t('btn_stt'),
                                  onTap: _toggleVoiceRecording,
                                ),
                                const SizedBox(width: 4),
                                _buildIconButton(
                                  icon: Icons.content_paste_rounded,
                                  color: colors.textSecondary,
                                  tooltip: lang.t('btn_paste'),
                                  onTap: () async {
                                    final data =
                                        await Clipboard.getData('text/plain');
                                    if (data?.text != null &&
                                        data!.text!.isNotEmpty) {
                                      _inputController.text = data.text!;
                                      _startTranslation();
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                _buildIconButton(
                                  icon: Icons.crop_free_rounded,
                                  color: colors.textSecondary,
                                  tooltip: lang.t('btn_ocr'),
                                  onTap: _triggerScreenSnip,
                                ),
                                const SizedBox(width: 4),
                                _buildIconButton(
                                  icon: Icons.image_outlined,
                                  color: colors.textSecondary,
                                  tooltip: 'Đính kèm ảnh',
                                  onTap: _attachImages,
                                ),
                                const SizedBox(width: 4),
                                _buildIconButton(
                                  icon: Icons.volume_up_outlined,
                                  color: colors.textSecondary,
                                  tooltip: lang.t('btn_tts'),
                                  onTap: () {
                                    if (_inputController.text
                                        .trim()
                                        .isNotEmpty) {
                                      TtsService.speak(
                                          _inputController.text, _srcLang);
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                if (_inputController.text.isNotEmpty)
                                  _buildIconButton(
                                    icon: Icons.clear_rounded,
                                    color: colors.accentRose,
                                    tooltip: lang.t('btn_clear'),
                                    onTap: () {
                                      _inputController.clear();
                                      _outputController.clear();
                                      setState(() {
                                        _attachedImages.clear();
                                        _statusText = 'READY';
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 0.5),

                        // Editor Field
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            maxLines: null,
                            expands: true,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textPrimary,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: lang.t('input_hint'),
                              hintStyle: TextStyle(
                                color: colors.textMuted.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        // Attached Image Previews
                        if (_attachedImages.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _attachedImages.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (ctx, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: colors.subCardBg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: colors.subCardBorder),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.image_rounded,
                                              size: 20),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Ảnh ${index + 1}',
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () => setState(() =>
                                                _attachedImages
                                                    .removeAt(index)),
                                            child: const Icon(
                                                Icons.close_rounded,
                                                size: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Right Bento: Output
                Expanded(
                  child: BentoCard(
                    colors: colors,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  PillBadge(
                                    label: _getLangName(_tgtLang, lang)
                                        .toUpperCase(),
                                    color: colors.accentEmerald,
                                    bg: colors.accentEmerald
                                        .withValues(alpha: 0.15),
                                    border: colors.accentEmerald
                                        .withValues(alpha: 0.4),
                                    icon: Icons.check_circle_outline_rounded,
                                    fontSize: 10,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '$outputChars ký tự',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Quick Action Tools
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIconButton(
                                  icon: Icons.subtitles_outlined,
                                  color: _showPinyin
                                      ? colors.accentCyan
                                      : colors.textSecondary,
                                  tooltip: lang.t('btn_pinyin'),
                                  onTap: () {
                                    setState(() => _showPinyin = !_showPinyin);
                                  },
                                ),
                                const SizedBox(width: 4),
                                _buildIconButton(
                                  icon: Icons.volume_up_rounded,
                                  color: colors.textSecondary,
                                  tooltip: lang.t('btn_tts'),
                                  onTap: () {
                                    if (_outputController.text
                                        .trim()
                                        .isNotEmpty) {
                                      TtsService.speak(
                                          _outputController.text, _tgtLang);
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                _buildIconButton(
                                  icon: Icons.copy_rounded,
                                  color: colors.accentCyan,
                                  tooltip: lang.t('btn_copy'),
                                  onTap: () {
                                    if (_outputController.text.isNotEmpty) {
                                      Clipboard.setData(
                                        ClipboardData(
                                            text: _outputController.text),
                                      );
                                      showAppToast(
                                        context,
                                        message: lang.t('toast_copied'),
                                        icon: Icons.check_rounded,
                                        accentColor: colors.accentEmerald,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 0.5),

                        // Result Field
                        Expanded(
                          child: Stack(
                            children: [
                              TextField(
                                controller: _outputController,
                                readOnly: true,
                                maxLines: null,
                                expands: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textPrimary,
                                  height: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: lang.t('output_hint'),
                                  hintStyle: TextStyle(
                                    color:
                                        colors.textMuted.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              if (_isLoading)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.subCardBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: colors.subCardBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                                colors.accentColor),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'STREAMING...',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: colors.accentColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Bottom Action Bar
          Row(
            children: [
              // Active Engine Indicator Capsule
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.subCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.subCardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppConfig.isLocalAi
                          ? Icons.memory_rounded
                          : Icons.cloud_outlined,
                      size: 16,
                      color: colors.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppConfig.isLocalAi
                          ? '${lang.tr('engine_local')}: ${switch (AppConfig.localEngine) {
                              'opus_mt' => 'OPUS-MT',
                              'gguf_native' =>
                                'GGUF · ${AppConfig.localGgufModel}',
                              _ => AppConfig.localGgufModel
                            }}'
                          : 'CLOUD: ${AppConfig.get('NVIDIA', 'model', defaultValue: 'Qwen 2.5')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.cardBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        readiness != 'engine_configured'
                            ? lang.tr(readiness)
                            : _statusText == 'READY'
                                ? lang.tr('engine_configured')
                                : _statusText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: readiness != 'engine_configured'
                              ? colors.accentAmber
                              : _statusText == 'ERROR'
                                  ? colors.accentRose
                                  : colors.accentEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Main Translation Button
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.accentColor, colors.accentCyan],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primaryGlow.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _startTranslation,
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      lang.t('btn_translating'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bolt_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      lang.t('btn_start_translation'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectorBar(AppColors colors, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Source Language Chips
            Text(
              '${lang.t('source_lang')}:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            ..._sourceLanguages.map((item) {
              final isSelected = _srcLang == item['code'];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildLangChip(
                  label: lang.t(item['labelKey']!),
                  isSelected: isSelected,
                  colors: colors,
                  onTap: () => _selectSourceLang(item['code']!),
                ),
              );
            }),

            const SizedBox(width: 8),

            // Swap Languages Button
            IconButton(
              icon: Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: _srcLang == 'auto'
                    ? colors.textMuted.withValues(alpha: 0.4)
                    : colors.accentCyan,
              ),
              tooltip: 'Đổi chiều ngôn ngữ',
              splashRadius: 18,
              onPressed: _srcLang == 'auto' ? null : _swapLanguages,
            ),

            const SizedBox(width: 8),

            // Target Language Chips
            Text(
              '${lang.t('target_lang')}:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            ..._targetLanguages.map((item) {
              final isSelected = _tgtLang == item['code'];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildLangChip(
                  label: lang.t(item['labelKey']!),
                  isSelected: isSelected,
                  colors: colors,
                  onTap: () => _selectTargetLang(item['code']!),
                ),
              );
            }),

            const SizedBox(width: 20),

            // Realtime Toggle Switch
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.t('realtime_translate'),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: _realtimeEnabled,
                  activeColor: colors.accentEmerald,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) {
                    setState(() => _realtimeEnabled = val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip({
    required String label,
    required bool isSelected,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentColor.withValues(alpha: 0.2)
              : colors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colors.accentColor
                : colors.borderDefault.withValues(alpha: 0.3),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.accentCyan : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  String _getLangName(String code, LanguageProvider lang) {
    switch (code) {
      case 'vi':
        return lang.t('lang_vi');
      case 'en':
        return lang.t('lang_en');
      case 'zh':
        return lang.t('lang_zh');
      case 'auto':
      default:
        return lang.t('lang_auto');
    }
  }
}
