// lib/modules/ui/main_window.dart
// Main visual translation dashboard widget (Liquid Glass theme)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../app_config.dart';
import '../logic.dart';
import '../document_translator.dart';
import 'styles.dart';
import 'dialogs.dart';
import 'localization.dart';
import '../translation_history.dart';

class MainWindow extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const MainWindow({
    super.key,
    required this.themeNotifier,
  });

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  AppColors get _c => widget.themeNotifier.colors;

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  
  bool _isLoading = false;
  String _status = 'Ready';
  
  String _srcLang = 'Auto';
  String _tgtLang = 'VN';
  String _uiLang = 'VN';
  
  List<String> _attachedImages = [];
  Timer? _debounceTimer;

  final GlobalKey _themeButtonKey = GlobalKey();

  int _activeTabIndex = 0; // 0 for Text, 1 for Document

  // Document translation state
  String? _selectedFilePath;
  String? _selectedFileName;
  int _selectedFileSize = 0;
  int _estimatedCharCount = 0;
  int _estimatedWordCount = 0;
  bool _isTranslatingDoc = false;
  double _docProgress = 0.0;
  String _docStatus = 'ready'; // ready, reading_file, translating_chunk, complete, error
  String? _docResultText;
  String? _docError;
  int _docCurrentChunk = 0;
  int _docTotalChunks = 0;
  StreamSubscription<DocumentTranslationProgress>? _docTranslationSubscription;
  int _historySubTabIndex = 0; // 0 for All, 1 for Saved

  @override
  void initState() {
    super.initState();
    _tgtLang = AppConfig.get('SETTINGS', 'default_target_lang', defaultValue: 'VN');
    _uiLang = AppConfig.get('SETTINGS', 'ui_lang', defaultValue: 'VN');
    _inputController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    _outputController.dispose();
    _debounceTimer?.cancel();
    _docTranslationSubscription?.cancel();
    super.dispose();
  }

  // ─── Debounced Auto Translate ──────────────────────────────────────────────
  void _onTextChanged() {
    if (_isLoading) return;
    _debounceTimer?.cancel();
    final delayStr = AppConfig.get('SETTINGS', 'auto_translate_delay', defaultValue: '0');
    final delay = int.tryParse(delayStr) ?? 0;
    if (delay > 0) {
      _debounceTimer = Timer(Duration(seconds: delay), () {
        _startTranslation();
      });
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────────
  void _clearAll() {
    setState(() {
      if (_activeTabIndex == 0) {
        _inputController.clear();
        _outputController.clear();
        _attachedImages.clear();
        _status = 'Ready';
      } else {
        if (!_isTranslatingDoc) {
          _selectedFilePath = null;
          _selectedFileName = null;
          _selectedFileSize = 0;
          _estimatedCharCount = 0;
          _estimatedWordCount = 0;
          _docProgress = 0.0;
          _docStatus = 'ready';
          _docResultText = null;
          _docError = null;
        }
      }
    });
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
          _status = 'ATTACHED ${_attachedImages.length} IMAGES';
        });
      }
    } catch (_) {}
  }

  void _startTranslation() async {
    if (_isLoading) return;
    final text = _inputController.text.trim();
    if (text.isEmpty && _attachedImages.isEmpty) return;

    _debounceTimer?.cancel();
    final isFromCache = _attachedImages.isEmpty && TranslateLogic.isCached(text, _srcLang, _tgtLang);
    setState(() {
      _isLoading = true;
      _outputController.clear();
      _status = isFromCache ? 'THINKING (CACHED)...' : 'THINKING...';
    });

    try {
      final responseStream = TranslateLogic.translate(
        text: text,
        sourceLang: _srcLang,
        targetLang: _tgtLang,
        imagePaths: _attachedImages,
      );

      await for (final chunk in responseStream) {
        _outputController.text += chunk;
      }

      // Check if pinyin translation is needed
      setState(() {
        _status = 'PROCESSING PINYIN...';
      });

      final chinesePattern = RegExp(r'[\u4e00-\u9fff]');
      final currentInput = _inputController.text;
      final currentOutput = _outputController.text;

      if (chinesePattern.hasMatch(currentInput)) {
        final pinyin = TranslateLogic.getPinyinOffline(currentInput);
        if (pinyin.isNotEmpty && !currentInput.contains('Pinyin:')) {
          _inputController.text = '$currentInput\n\nPinyin:\n$pinyin';
        }
      } else if (chinesePattern.hasMatch(currentOutput)) {
        final pinyin = TranslateLogic.getPinyinOffline(currentOutput);
        if (pinyin.isNotEmpty && !currentOutput.contains('Pinyin:')) {
          _outputController.text = '$currentOutput\n\nPinyin:\n$pinyin';
        }
      }

      // Add to history
      final finalOutput = _outputController.text.trim();
      if (finalOutput.isNotEmpty) {
        TranslationHistory.addRecord(text, finalOutput, _srcLang, _tgtLang);
      }

      setState(() {
        _status = isFromCache ? 'COMPLETE (CACHED)' : 'COMPLETE';
      });
    } catch (e) {
      setState(() {
        _status = 'ERROR';
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                )
              ],
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _attachedImages.clear();
      });
    }
  }

  void _copyToClipboard(TextEditingController controller, String label) {
    var text = controller.text.trim();
    if (text.contains('Pinyin:')) {
      text = text.split('Pinyin:')[0].trim();
    }
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UiLocalizations.get('copied_toast', _uiLang)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _changeSrcLang(String code) {
    setState(() {
      _srcLang = code;
      if (_srcLang != 'Auto' && _srcLang == _tgtLang) {
        _tgtLang = _srcLang != 'VN' ? 'VN' : 'CN';
      }
    });
  }

  void _changeTgtLang(String code) {
    setState(() {
      _tgtLang = code;
      if (_tgtLang == _srcLang) {
        _srcLang = 'Auto';
      }
    });
  }

  void _swapLanguages() {
    if (_isLoading) return;
    final oldSrc = _srcLang;
    final oldTgt = _tgtLang;
    setState(() {
      if (oldSrc == 'Auto') {
        _srcLang = oldTgt;
        _tgtLang = oldTgt != 'VN' ? 'VN' : 'CN';
      } else {
        _srcLang = oldTgt;
        _tgtLang = oldSrc;
      }
    });
  }

  // ─── Document Translation Actions ─────────────────────────────────────────
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _selectDocumentFile() async {
    if (_isTranslatingDoc) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'docx', 'xlsx', 'pptx', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        if (await file.exists()) {
          final name = result.files.single.name;
          final size = await file.length();

          setState(() {
            _selectedFilePath = path;
            _selectedFileName = name;
            _selectedFileSize = size;
            _docProgress = 0.0;
            _docStatus = 'reading_file';
            _docResultText = null;
            _docError = null;
          });

          // Fetch stats asynchronously so UI is not blocked
          final stats = await DocumentTranslator.getFileStats(path);
          setState(() {
            _estimatedCharCount = stats.charCount;
            _estimatedWordCount = stats.wordCount;
            _docStatus = 'ready';
          });
        }
      }
    } catch (e) {
      setState(() {
        _docError = e.toString();
        _docStatus = 'error';
      });
    }
  }

  void _startDocTranslation() {
    if (_isTranslatingDoc || _selectedFilePath == null) return;
    
    setState(() {
      _isTranslatingDoc = true;
      _docProgress = 0.0;
      _docStatus = 'reading_file';
      _docResultText = null;
      _docError = null;
    });

    _docTranslationSubscription = DocumentTranslator.translateDocument(
      filePath: _selectedFilePath!,
      sourceLang: _srcLang,
      targetLang: _tgtLang,
    ).listen((progress) {
      setState(() {
        _docProgress = progress.percentage;
        _docStatus = progress.status;
        _docCurrentChunk = progress.currentChunk;
        _docTotalChunks = progress.totalChunks;
        if (progress.status == 'complete') {
          _docResultText = progress.resultText;
          _isTranslatingDoc = false;
          _autoSaveTranslatedFile(progress.resultText);
        } else if (progress.status.startsWith('error')) {
          _docError = progress.error;
          _isTranslatingDoc = false;
        }
      });
    }, onError: (e) {
      setState(() {
        _docError = e.toString();
        _docStatus = 'error';
        _isTranslatingDoc = false;
      });
    }, onDone: () {
      setState(() {
        _isTranslatingDoc = false;
      });
    });
  }

  Future<void> _autoSaveTranslatedFile(String? resultText) async {
    if (resultText == null || _selectedFilePath == null) return;
    try {
      final inputPath = _selectedFilePath!;
      final file = File(inputPath);
      final dir = file.parent.path;
      final originalName = _selectedFileName ?? 'translated';
      final parts = originalName.split('.');
      final ext = parts.last;
      final baseName = parts.sublist(0, parts.length - 1).join('.');
      
      final suffix = '_$_tgtLang'; // e.g. _VN or _CN
      final finalOutputPath = '$dir/${baseName}$suffix.$ext';
      
      final extLower = ext.toLowerCase();
      if (extLower == 'pdf' || extLower == 'xlsx' || extLower == 'pptx' || extLower == 'docx') {
        final tempFile = File(resultText);
        if (await tempFile.exists()) {
          await tempFile.copy(finalOutputPath);
        } else {
          throw Exception("Temporary translated file not found.");
        }
      } else {
        final fileOut = File(finalOutputPath);
        await fileOut.writeAsString(resultText, encoding: utf8);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${UiLocalizations.get('save_success', _uiLang)}: $finalOutputPath'),
            backgroundColor: _c.statusActive,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${UiLocalizations.get('save_error', _uiLang)}: $e'),
            backgroundColor: _c.statusRemoved,
          ),
        );
      }
    }
  }

  void _cancelDocTranslation() {
    if (!_isTranslatingDoc) return;
    _docTranslationSubscription?.cancel();
    setState(() {
      _isTranslatingDoc = false;
      _docStatus = 'ready';
      _docProgress = 0.0;
    });
  }

  Future<void> _saveTranslatedDoc() async {
    if (_docResultText == null || _selectedFilePath == null) return;
    try {
      final originalName = _selectedFileName ?? 'translated';
      final parts = originalName.split('.');
      final ext = parts.last.toLowerCase();
      final baseName = parts.sublist(0, parts.length - 1).join('.');
      
      // Default suggested name
      final suggestedName = '${baseName}_translated.$ext';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: UiLocalizations.get('save_translated', _uiLang),
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: [ext],
      );

      if (result != null) {
        if (ext == 'pdf' || ext == 'xlsx' || ext == 'pptx' || ext == 'docx') {
          // Copy binary file
          final tempFile = File(_docResultText!);
          if (await tempFile.exists()) {
            await tempFile.copy(result);
          } else {
            throw Exception("Temporary translated file not found.");
          }
        } else {
          // Write text string (for txt, md)
          final file = File(result);
          await file.writeAsString(_docResultText!, encoding: utf8);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(UiLocalizations.get('save_success', _uiLang)),
              backgroundColor: _c.statusActive,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${UiLocalizations.get('save_error', _uiLang)}: $e'),
            backgroundColor: _c.statusRemoved,
          ),
        );
      }
    }
  }

  String _getTranslatedDocStatus() {
    switch (_docStatus) {
      case 'ready':
        return UiLocalizations.get('ready_translate', _uiLang);
      case 'reading_file':
        return UiLocalizations.get('reading_file', _uiLang);
      case 'translating_chunk':
        final template = UiLocalizations.get('translating_chunk', _uiLang);
        return template
            .replaceAll('{chunk}', _docCurrentChunk.toString())
            .replaceAll('{total}', _docTotalChunks.toString());
      case 'complete':
        return UiLocalizations.get('complete', _uiLang);
      case 'error_reading_file':
        return UiLocalizations.get('error_reading_file', _uiLang);
      case 'error_empty_file':
        return UiLocalizations.get('error_empty_file', _uiLang);
      case 'error_api':
        return '${UiLocalizations.get('error', _uiLang)}: ${_docError ?? "API Error"}';
      case 'error':
        return '${UiLocalizations.get('error', _uiLang)}: ${_docError ?? "Unknown Error"}';
      default:
        return _docStatus;
    }
  }

  // ─── Theme circular reveal trigger ─────────────────────────────────────────
  void _toggleThemeReveal() {
    final revealState = context.findAncestorStateOfType<ThemeRevealState>();
    if (revealState != null) {
      revealState.triggerReveal(
        buttonKey: _themeButtonKey,
        onToggle: () {
          final brightness = MediaQuery.of(context).platformBrightness;
          widget.themeNotifier.toggle(brightness);
        },
      );
    }
  }

  void _toggleUiLang() async {
    final nextLang = _uiLang == 'VN' ? 'ENG' : (_uiLang == 'ENG' ? 'CN' : 'VN');
    setState(() {
      _uiLang = nextLang;
    });
    await AppConfig.set('SETTINGS', 'ui_lang', nextLang);
  }

  String _getTranslatedStatus() {
    if (_status.startsWith('ATTACHED ')) {
      final count = _status.split(' ')[1];
      final template = UiLocalizations.get('attached_images_status', _uiLang);
      return template.replaceAll('{count}', count);
    }
    if (_status.startsWith('PROXY UPDATED: ')) {
      final state = _status.substring('PROXY UPDATED: '.length);
      final isEnabled = state == 'ENABLED';
      final stateStr = UiLocalizations.get(
          isEnabled ? 'proxy_enabled_status' : 'proxy_disabled_status', _uiLang);
      final template = UiLocalizations.get('proxy_updated_status', _uiLang);
      return template.replaceAll('{state}', stateStr);
    }
    
    final isCached = _status.contains('(CACHED)');
    final cleanStatus = _status.replaceAll('(CACHED)', '').trim();
    final lowerStatus = cleanStatus.toLowerCase().replaceAll('...', '');
    
    String result = cleanStatus;
    if (lowerStatus == 'ready') {
      result = UiLocalizations.get('ready', _uiLang);
    } else if (lowerStatus == 'thinking') {
      result = UiLocalizations.get('thinking', _uiLang);
    } else if (lowerStatus == 'processing pinyin') {
      result = UiLocalizations.get('processing_pinyin', _uiLang);
    } else if (lowerStatus == 'complete') {
      result = UiLocalizations.get('complete', _uiLang);
    } else if (lowerStatus == 'error') {
      result = UiLocalizations.get('error', _uiLang);
    }
    
    if (isCached) {
      if (_uiLang == 'VN') {
        return '$result (BẢN NHỚ)';
      } else if (_uiLang == 'CN') {
        return '$result (已缓存)';
      } else {
        return '$result (CACHED)';
      }
    }
    return result;
  }

  // ─── Layout widgets ────────────────────────────────────────────────────────

  Widget _buildTitleBar() {
    String themeLabelKey = 'theme_auto';
    final modeLabelUpper = widget.themeNotifier.modeLabel.toUpperCase();
    if (modeLabelUpper == 'DARK') {
      themeLabelKey = 'theme_dark';
    } else if (modeLabelUpper == 'LIGHT') {
      themeLabelKey = 'theme_light';
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.translate, size: 18, color: _c.linkAccent),
          const SizedBox(width: 8),
          Text(
            'JA TRANSLATE • LIQUID GLASS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _c.textPrimary,
              letterSpacing: 2.0,
            ),
          ),
          const Spacer(),
          // Proxy Setup Button
          TextButton.icon(
            icon: Icon(Icons.language, size: 16, color: _c.textPrimary),
            label: Text(
              UiLocalizations.get('proxy_btn', _uiLang),
              style: TextStyle(color: _c.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: ProxyDialog(uiLang: _uiLang),
                ),
              ).then((updated) {
                if (updated == true) {
                  final proxyEnabled = AppConfig.get('PROXY', 'enabled') == 'true';
                  setState(() {
                    _status = 'PROXY UPDATED: ${proxyEnabled ? 'ENABLED' : 'DISABLED'}';
                  });
                }
              });
            },
          ),
          const SizedBox(width: 8),
          // Theme toggle button
          TextButton.icon(
            key: _themeButtonKey,
            icon: Icon(
              widget.themeNotifier.modeIcon,
              size: 16,
              color: _c.textPrimary,
            ),
            label: Text(
              UiLocalizations.get(themeLabelKey, _uiLang),
              style: TextStyle(color: _c.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: _toggleThemeReveal,
          ),
          const SizedBox(width: 8),
          // UI Language Toggle Button
          TextButton.icon(
            icon: Icon(Icons.g_translate, size: 16, color: _c.textPrimary),
            label: Text(
              _uiLang.toUpperCase(),
              style: TextStyle(color: _c.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: _toggleUiLang,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String label, bool isSelected, VoidCallback onPressed, Color activeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.8) : _c.bgTertiary,
            border: Border.all(
              color: isSelected ? activeColor : _c.borderDefault,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : _c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelectorPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Source side
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(UiLocalizations.get('source', _uiLang), style: TextStyle(color: _c.linkAccent, fontWeight: FontWeight.bold, fontSize: 10)),
              const SizedBox(height: 6),
              Row(
                children: ['Auto', 'VN', 'ENG', 'CN'].map((code) {
                  final label = code == 'Auto' ? UiLocalizations.get('lang_auto', _uiLang) : code;
                  return _buildLanguageButton(
                    label,
                    _srcLang == code,
                    () => _changeSrcLang(code),
                    _c.linkAccent,
                  );
                }).toList(),
              ),
            ],
          ),
          // Swap Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Tooltip(
                  message: UiLocalizations.get('tooltip_swap', _uiLang),
                  child: IconButton(
                    icon: Icon(Icons.swap_horiz, size: 22, color: _c.textSecondary),
                    onPressed: _swapLanguages,
                  ),
                ),
              ],
            ),
          ),
          // Target side
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(UiLocalizations.get('target', _uiLang), style: TextStyle(color: _c.targetAccent, fontWeight: FontWeight.bold, fontSize: 10)),
              const SizedBox(height: 6),
              Row(
                children: ['VN', 'ENG', 'CN'].map((code) {
                  return _buildLanguageButton(
                    code,
                    _tgtLang == code,
                    () => _changeTgtLang(code),
                    _c.targetAccent,
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Tab bar (Text/Doc switcher)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _uiLang == 'VN' ? 'CHẾ ĐỘ' : (_uiLang == 'ENG' ? 'MODE' : '模式'),
                style: TextStyle(color: _c.textMuted, fontWeight: FontWeight.bold, fontSize: 10),
              ),
              const SizedBox(height: 6),
              _buildTabBar(),
            ],
          ),
          const Spacer(),
          // Clear Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildLanguageButton(
                UiLocalizations.get('clear', _uiLang),
                false,
                _clearAll,
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorField({
    required TextEditingController controller,
    required String title,
    required String hint,
    required bool readOnly,
    required Color fontColor,
    required double fontSize,
    required String fontFamily,
    required bool isInput,
    List<Widget> actions = const [],
  }) {
    final isTransparent = AppConfig.enableTransparency;

    // Convert actions to compact size for header integration
    final List<Widget> compactActions = actions.map((a) {
      if (a is IconButton) {
        return SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            icon: a.icon,
            onPressed: a.onPressed,
            tooltip: a.tooltip,
            padding: EdgeInsets.zero,
            iconSize: 16,
            splashRadius: 14,
          ),
        );
      }
      return a;
    }).toList();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: _c.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              if (compactActions.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: compactActions,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: readOnly
                        ? (isTransparent ? _c.bgSecondary.withOpacity(0.15) : _c.bgSecondary)
                        : (isTransparent ? _c.bgSecondary.withOpacity(0.3) : _c.bgSecondary),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTransparent ? _c.borderDefault.withOpacity(0.12) : _c.borderDefault,
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 14,
                    bottom: (isInput && _attachedImages.isNotEmpty) ? 60 : 14,
                  ),
                  child: TextField(
                    controller: controller,
                    readOnly: readOnly,
                    maxLines: null,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: fontSize,
                      color: fontColor,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      fillColor: Colors.transparent,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                // Attached Images Chips Row for INPUT
                if (isInput && _attachedImages.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _attachedImages.length,
                        itemBuilder: (context, index) {
                          final path = _attachedImages[index];
                          final fileName = path.split('\\').last.split('/').last;
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _c.bgTertiary.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _c.borderDefault.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image, size: 14, color: _c.linkAccent),
                                const SizedBox(width: 6),
                                Text(
                                  fileName,
                                  style: TextStyle(fontSize: 11, color: _c.textSecondary, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _attachedImages.removeAt(index);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Icon(Icons.close, size: 14, color: _c.statusRemoved),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final isTransparent = AppConfig.enableTransparency;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isTransparent ? _c.bgTertiary.withOpacity(0.3) : _c.bgTertiary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTransparent ? _c.borderDefault.withOpacity(0.08) : _c.borderDefault,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(0, UiLocalizations.get('tab_text', _uiLang)),
          _buildTabButton(1, UiLocalizations.get('tab_doc', _uiLang)),
          _buildTabButton(2, UiLocalizations.get('tab_history', _uiLang)),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        if (_isLoading || _isTranslatingDoc) return;
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _c.linkAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _c.linkAccent.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isSelected ? Colors.white : _c.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTranslationView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Side: File Selection & Info
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UiLocalizations.get('file_info', _uiLang).toUpperCase(),
                  style: TextStyle(
                    color: _c.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: _selectedFilePath == null
                      ? InkWell(
                          onTap: _selectDocumentFile,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _c.borderDefault.withOpacity(0.3),
                                style: BorderStyle.solid,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 48,
                                    color: _c.linkAccent,
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      UiLocalizations.get('drag_drop_hint', _uiLang),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _c.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    UiLocalizations.get('supported_formats_hint', _uiLang),
                                    style: TextStyle(
                                      color: _c.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text(UiLocalizations.get('select_file', _uiLang)),
                                    onPressed: _selectDocumentFile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _c.linkAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _c.bgSecondary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _c.borderDefault.withOpacity(0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _selectedFileName!.endsWith('.pdf')
                                        ? Icons.picture_as_pdf
                                        : (_selectedFileName!.endsWith('.xlsx')
                                            ? Icons.table_chart
                                            : (_selectedFileName!.endsWith('.pptx')
                                                ? Icons.slideshow
                                                : (_selectedFileName!.endsWith('.docx')
                                                    ? Icons.description
                                                    : Icons.article))),
                                    color: _selectedFileName!.endsWith('.pdf')
                                        ? Colors.redAccent
                                        : (_selectedFileName!.endsWith('.xlsx')
                                            ? Colors.green
                                            : (_selectedFileName!.endsWith('.pptx')
                                                ? Colors.orange
                                                : _c.linkAccent)),
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedFileName!,
                                          style: TextStyle(
                                            color: _c.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatFileSize(_selectedFileSize),
                                          style: TextStyle(
                                            color: _c.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: _c.statusRemoved),
                                    onPressed: _isTranslatingDoc
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedFilePath = null;
                                              _selectedFileName = null;
                                              _selectedFileSize = 0;
                                              _estimatedCharCount = 0;
                                              _estimatedWordCount = 0;
                                              _docProgress = 0.0;
                                              _docStatus = 'ready';
                                              _docResultText = null;
                                              _docError = null;
                                            });
                                          },
                                    tooltip: UiLocalizations.get('remove_file', _uiLang),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                UiLocalizations.get('file_path', _uiLang),
                                _selectedFilePath!,
                                isPath: true,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                UiLocalizations.get('char_count', _uiLang),
                                _estimatedCharCount > 0 ? _estimatedCharCount.toString() : '...',
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                UiLocalizations.get('word_count', _uiLang),
                                _estimatedWordCount > 0 ? _estimatedWordCount.toString() : '...',
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Right Side: Progress & Actions
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UiLocalizations.get('result_title', _uiLang).toUpperCase(),
                  style: TextStyle(
                    color: _c.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isTranslatingDoc && _docResultText == null && _docError == null) ...[
                        Icon(
                          Icons.translate,
                          size: 48,
                          color: _c.textMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          UiLocalizations.get('ready_translate', _uiLang),
                          style: TextStyle(
                            color: _c.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else if (_isTranslatingDoc) ...[
                        BlinkingDot(size: 12, color: _c.linkAccent),
                        const SizedBox(height: 16),
                        Text(
                          _getTranslatedDocStatus(),
                          style: TextStyle(
                            color: _c.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _docProgress,
                              minHeight: 6,
                              backgroundColor: _c.borderDefault.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(_c.linkAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_docProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _c.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cancel, size: 16),
                          label: Text(UiLocalizations.get('proxy_cancel', _uiLang)),
                          onPressed: _cancelDocTranslation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _c.statusRemoved,
                            side: BorderSide(color: _c.statusRemoved.withOpacity(0.5)),
                          ),
                        ),
                      ] else if (_docResultText != null) ...[
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: _c.statusActive,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          UiLocalizations.get('complete', _uiLang),
                          style: TextStyle(
                            color: _c.statusActive,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download, size: 16),
                          label: Text(UiLocalizations.get('save_translated', _uiLang)),
                          onPressed: _saveTranslatedDoc,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _c.targetAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ] else if (_docError != null) ...[
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: _c.statusRemoved,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _getTranslatedDocStatus(),
                            style: TextStyle(
                              color: _c.statusRemoved,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_selectedFilePath != null) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(UiLocalizations.get('start_translation', _uiLang)),
                            onPressed: _startDocTranslation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _c.linkAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPath = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _c.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        isPath
            ? Tooltip(
                message: value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _c.bgPrimary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: StyledWidgets.pathDisplay(value, c: _c),
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  color: _c.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool useRoundCorners = !Platform.isWindows || AppConfig.isWindows11;
    final borderRadius = useRoundCorners ? BorderRadius.circular(15) : BorderRadius.zero;

    return Container(
      decoration: BoxDecoration(
        color: _c.bgPrimary,
        borderRadius: borderRadius,
        border: Border.all(color: _c.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Scaffold(
          body: Column(
            children: [
              _buildTitleBar(),
              Divider(height: 1, color: _c.borderDefault.withOpacity(0.1)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Column(
                    children: [
                      _buildLanguageSelectorPanel(),
                      const SizedBox(height: 10),
                      // Body views based on active tab
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.02),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _activeTabIndex == 0
                              ? Focus(
                                  key: const ValueKey('text_translation'),
                                  onKeyEvent: (node, event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey == LogicalKeyboardKey.enter &&
                                        HardwareKeyboard.instance.isControlPressed) {
                                      _startTranslation();
                                      return KeyEventResult.handled;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: Row(
                                    children: [
                                      _buildEditorField(
                                        controller: _inputController,
                                        title: UiLocalizations.get('input_title', _uiLang),
                                        hint: UiLocalizations.get('input_hint', _uiLang),
                                        readOnly: _isLoading,
                                        fontColor: _c.textPrimary,
                                        fontSize: 14,
                                        fontFamily: 'JetBrains Mono',
                                        isInput: true,
                                        actions: [
                                          IconButton(
                                            icon: const Icon(Icons.attach_file, size: 16),
                                            onPressed: _isLoading ? null : _attachImages,
                                            tooltip: UiLocalizations.get('tooltip_attach', _uiLang),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy, size: 16),
                                            onPressed: () => _copyToClipboard(_inputController, 'Input'),
                                            tooltip: UiLocalizations.get('tooltip_copy_input', _uiLang),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      _buildEditorField(
                                        controller: _outputController,
                                        title: UiLocalizations.get('result_title', _uiLang),
                                        hint: UiLocalizations.get('result_hint', _uiLang),
                                        readOnly: true,
                                        fontColor: _c.textPrimary,
                                        fontSize: 15,
                                        fontFamily: 'Segoe UI',
                                        isInput: false,
                                        actions: [
                                          if (_outputController.text.trim().isNotEmpty && !_isLoading)
                                            IconButton(
                                              icon: Icon(
                                                _isCurrentResultSaved ? Icons.star : Icons.star_border,
                                                size: 16,
                                                color: _isCurrentResultSaved ? Colors.amber : null,
                                              ),
                                              onPressed: _toggleSaveCurrentTranslation,
                                              tooltip: UiLocalizations.get(
                                                _isCurrentResultSaved ? 'tooltip_unsave' : 'tooltip_save',
                                                _uiLang,
                                              ),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.copy, size: 16),
                                            onPressed: () => _copyToClipboard(_outputController, 'Result'),
                                            tooltip: UiLocalizations.get('tooltip_copy_result', _uiLang),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : _activeTabIndex == 1
                                  ? KeyedSubtree(
                                      key: const ValueKey('document_translation'),
                                      child: _buildDocumentTranslationView(),
                                    )
                                  : KeyedSubtree(
                                      key: const ValueKey('history_view'),
                                      child: _buildHistoryView(),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Bottom control depending on active tab
                      if (_activeTabIndex == 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTranslatedStatus().toUpperCase(),
                                    style: TextStyle(
                                      color: _c.textPrimary.withOpacity(0.6),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (_isLoading) ...[
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        minHeight: 4,
                                        backgroundColor: _c.borderDefault.withOpacity(0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(_c.linkAccent),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Tooltip(
                              message: 'Switch UI Language',
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(Icons.language, size: 14, color: _c.textPrimary.withOpacity(0.6)),
                                label: Text(
                                  _uiLang.toUpperCase(),
                                  style: TextStyle(
                                    color: _c.textPrimary.withOpacity(0.6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _toggleUiLang,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Translation trigger button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _c.linkAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isLoading ? null : _startTranslation,
                            child: Text(
                              _isLoading
                                  ? UiLocalizations.get('thinking', _uiLang).toUpperCase()
                                  : UiLocalizations.get('start_translation', _uiLang).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ] else if (_activeTabIndex == 1) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _c.linkAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: (_selectedFilePath == null || _isTranslatingDoc)
                                ? null
                                : _startDocTranslation,
                            child: Text(
                              _isTranslatingDoc
                                  ? UiLocalizations.get('thinking', _uiLang).toUpperCase()
                                  : UiLocalizations.get('start_translation', _uiLang).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isCurrentResultSaved {
    final text = _inputController.text.trim();
    final translated = _outputController.text.trim();
    if (text.isEmpty || translated.isEmpty) return false;
    return TranslationHistory.isSaved(text, translated, _srcLang, _tgtLang);
  }

  void _toggleSaveCurrentTranslation() {
    final text = _inputController.text.trim();
    final translated = _outputController.text.trim();
    if (text.isEmpty || translated.isEmpty) return;
    
    setState(() {
      TranslationHistory.toggleSaveForTranslation(text, translated, _srcLang, _tgtLang);
    });
    
    final isSaved = _isCurrentResultSaved;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(UiLocalizations.get(isSaved ? 'toast_saved' : 'toast_unsaved', _uiLang)),
        duration: const Duration(seconds: 1),
        backgroundColor: isSaved ? _c.statusActive : _c.statusRemoved,
      ),
    );
  }

  Widget _buildHistoryView() {
    final isTransparent = AppConfig.enableTransparency;
    final allRecords = TranslationHistory.records;
    final filteredRecords = _historySubTabIndex == 0
        ? allRecords
        : allRecords.where((r) => r.isSaved).toList();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isTransparent ? _c.bgTertiary.withOpacity(0.3) : _c.bgTertiary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTransparent ? _c.borderDefault.withOpacity(0.08) : _c.borderDefault,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHistorySubTabButton(0, UiLocalizations.get('subtab_all', _uiLang)),
                    _buildHistorySubTabButton(1, UiLocalizations.get('subtab_saved', _uiLang)),
                  ],
                ),
              ),
              const Spacer(),
              if (_historySubTabIndex == 0 && filteredRecords.isNotEmpty)
                TextButton.icon(
                  icon: Icon(Icons.delete_sweep, size: 16, color: _c.statusRemoved),
                  label: Text(
                    UiLocalizations.get('clear_history', _uiLang),
                    style: TextStyle(color: _c.statusRemoved, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: AlertDialog(
                          title: Text(UiLocalizations.get('clear_history', _uiLang)),
                          content: Text(_uiLang == 'VN'
                              ? 'Bạn có chắc chắn muốn xóa toàn bộ lịch sử dịch (giữ lại các bản dịch đã lưu)?'
                              : (_uiLang == 'ENG'
                                  ? 'Are you sure you want to clear all translation history (saved items will be kept)?'
                                  : '您确定要清除所有翻译历史记录吗（已保存的项目将被保留）？')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(UiLocalizations.get('proxy_cancel', _uiLang)),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  TranslationHistory.clearHistory();
                                });
                                Navigator.of(ctx).pop();
                              },
                              style: TextButton.styleFrom(foregroundColor: _c.statusRemoved),
                              child: Text(UiLocalizations.get('clear', _uiLang)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _historySubTabIndex == 0 ? Icons.history : Icons.star_outline,
                          size: 48,
                          color: _c.textMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          UiLocalizations.get('no_records', _uiLang),
                          style: TextStyle(
                            color: _c.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = filteredRecords[index];
                      return _buildHistoryRecordCard(record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySubTabButton(int index, String label) {
    final isSelected = _historySubTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _historySubTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _c.bgSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? _c.borderDefault : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? _c.textPrimary : _c.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRecordCard(TranslationRecord record) {
    final formattedTime = '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')} ${record.timestamp.day}/${record.timestamp.month}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _c.bgSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _c.borderDefault.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            setState(() {
              _inputController.text = record.text;
              _outputController.text = record.translated;
              _srcLang = record.srcLang;
              _tgtLang = record.tgtLang;
              _activeTabIndex = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_uiLang == 'VN' ? 'Đã tải bản dịch từ lịch sử' : (_uiLang == 'ENG' ? 'Loaded translation from history' : '已从历史记录加载翻译')),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _c.bgTertiary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _c.borderDefault.withOpacity(0.2)),
                  ),
                  child: Text(
                    '${record.srcLang} ➔ ${record.tgtLang}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _c.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.text.replaceAll('\n', ' '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.translated.replaceAll('\n', ' '),
                        style: TextStyle(
                          fontSize: 12,
                          color: _c.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  formattedTime,
                  style: TextStyle(fontSize: 10, color: _c.textMuted),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    record.isSaved ? Icons.star : Icons.star_border,
                    size: 18,
                    color: record.isSaved ? Colors.amber : _c.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      TranslationHistory.toggleSave(record.id);
                    });
                  },
                  splashRadius: 16,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: _c.statusRemoved),
                  onPressed: () {
                    setState(() {
                      TranslationHistory.deleteRecord(record.id);
                    });
                  },
                  splashRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
