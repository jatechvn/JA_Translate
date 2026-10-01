import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/app_toast.dart';
import '../modules/document_translator.dart';

class DocumentTranslationView extends StatefulWidget {
  const DocumentTranslationView({super.key});

  @override
  State<DocumentTranslationView> createState() =>
      _DocumentTranslationViewState();
}

class _DocumentTranslationViewState extends State<DocumentTranslationView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _selectedFilePath;
  DocumentFileStats? _fileStats;

  final String _srcLang = 'auto';
  final String _tgtLang = 'vi';

  bool _optVietnameseFont = true;
  bool _optPinyinAnnotation = true;

  bool _isTranslating = false;
  double _progress = 0.0;
  String _statusMessage = 'Sẵn sàng dịch';
  String? _resultText;
  String? _errorMessage;

  StreamSubscription<DocumentTranslationProgress>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _pickDocumentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'xlsx', 'pptx', 'txt', 'md'],
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
          setState(() {
            _selectedFilePath = path;
            _progress = 0.0;
            _resultText = null;
            _errorMessage = null;
            _statusMessage = 'Đang phân tích tệp...';
          });

          try {
            final stats = await DocumentTranslator.getFileStats(path);
            if (mounted) {
              setState(() {
                _fileStats = stats;
                _statusMessage = 'Đã sẵn sàng dịch tài liệu';
              });
            }
          } catch (_) {
            if (mounted) {
              setState(() => _statusMessage = 'Đã chọn tệp');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          message: 'Lỗi chọn tệp: $e',
          icon: Icons.error_outline_rounded,
          accentColor: context.read<ThemeProvider>().colors.accentRose,
        );
      }
    }
  }

  void _startDocumentTranslation() {
    if (_selectedFilePath == null || _isTranslating) return;

    setState(() {
      _isTranslating = true;
      _progress = 0.0;
      _statusMessage = 'Bắt đầu quá trình dịch tài liệu...';
      _resultText = null;
      _errorMessage = null;
    });

    _subscription?.cancel();
    final stream = DocumentTranslator.translateDocument(
      filePath: _selectedFilePath!,
      sourceLang: _srcLang,
      targetLang: _tgtLang,
    );

    _subscription = stream.listen(
      (p) {
        if (!mounted) return;
        setState(() {
          _progress = p.percentage;
          _statusMessage = p.status;
          if (p.resultText != null) {
            _resultText = p.resultText;
          }
          if (p.error != null) {
            _errorMessage = p.error;
            _isTranslating = false;
          }
          if (p.percentage >= 1.0) {
            _isTranslating = false;
            _statusMessage = 'Hoàn tất dịch tài liệu!';
          }
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isTranslating = false;
          _errorMessage = err.toString();
          _statusMessage = 'Lỗi dịch tài liệu';
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isTranslating = false;
        });
      },
    );
  }

  void _cancelTranslation() {
    _subscription?.cancel();
    setState(() {
      _isTranslating = false;
      _statusMessage = 'Đã hủy dịch';
    });
  }

  void _openResultFolder() {
    if (_selectedFilePath == null) return;
    final parentDir = File(_selectedFilePath!).parent.path;
    if (Platform.isWindows) {
      Process.run('explorer.exe', [parentDir]);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final colors = theme.colors;

    final fileName = _selectedFilePath?.split(Platform.pathSeparator).last;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. File Picker & Dropzone Bento Card
          BentoCard(
            colors: colors,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.description_rounded,
                              color: colors.accentCyan,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('doc_title'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  lang.t('doc_desc'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isTranslating ? null : _pickDocumentFile,
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label: Text(lang.t('doc_browse')),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selected File Badge
                if (_selectedFilePath != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.subCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.subCardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file_rounded,
                            color: colors.accentEmerald, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _fileStats != null
                                    ? 'Ước tính: ${_fileStats!.charCount} ký tự • ${_fileStats!.wordCount} từ'
                                    : _selectedFilePath!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: colors.textMuted,
                          onPressed: _isTranslating
                              ? null
                              : () => setState(() {
                                    _selectedFilePath = null;
                                    _fileStats = null;
                                    _resultText = null;
                                  }),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: _pickDocumentFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: colors.subCardBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.borderDefault.withValues(alpha: 0.4),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: colors.accentCyan.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.t('doc_drop_hint'),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hỗ trợ: PDF (.pdf), Microsoft Word (.docx), Excel (.xlsx), PowerPoint (.pptx), TXT, Markdown',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Options & Translation Control Bento Card
          BentoCard(
            colors: colors,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấu Hình Bản Dịch Tài Liệu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Vietnamese font optimization toggle
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.subCardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.subCardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.font_download_outlined,
                                color: colors.accentCyan, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lang.t('doc_viet_font_opt'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: _optVietnameseFont,
                              activeColor: colors.accentEmerald,
                              onChanged: (val) =>
                                  setState(() => _optVietnameseFont = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Pinyin annotation toggle
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.subCardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.subCardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.translate_rounded,
                                color: colors.accentAmber, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lang.t('doc_pinyin_annot'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: _optPinyinAnnotation,
                              activeColor: colors.accentEmerald,
                              onChanged: (val) =>
                                  setState(() => _optPinyinAnnotation = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress Bar
                if (_isTranslating || _progress > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.accentCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.accentCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      minHeight: 8,
                      backgroundColor: colors.subCardBg,
                      valueColor: AlwaysStoppedAnimation(colors.accentColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.accentRose,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_resultText != null) ...[
                  Text(
                    _resultText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.accentEmerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isTranslating)
                      OutlinedButton.icon(
                        onPressed: _cancelTranslation,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Hủy'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.accentRose,
                          side: BorderSide(color: colors.accentRose),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    if (_selectedFilePath != null && !_isTranslating) ...[
                      OutlinedButton.icon(
                        onPressed: _openResultFolder,
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: Text(lang.t('doc_export_result')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.borderDefault),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _startDocumentTranslation,
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: Text(lang.t('doc_btn_translate')),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
