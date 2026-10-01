import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/app_toast.dart';
import '../modules/translation_history.dart';

class TranslationHistoryView extends StatefulWidget {
  final void Function(String text, String src, String tgt)? onRestoreText;

  const TranslationHistoryView({super.key, this.onRestoreText});

  @override
  State<TranslationHistoryView> createState() => _TranslationHistoryViewState();
}

class _TranslationHistoryViewState extends State<TranslationHistoryView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  bool _onlySaved = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TranslationRecord> get _filteredRecords {
    final query = _searchController.text.trim().toLowerCase();
    var list = _onlySaved
        ? TranslationHistory.records.where((r) => r.isSaved).toList()
        : TranslationHistory.records;

    if (query.isNotEmpty) {
      list = list.where((r) {
        return r.text.toLowerCase().contains(query) ||
            r.translated.toLowerCase().contains(query);
      }).toList();
    }
    return list;
  }

  void _clearAllHistory() {
    final theme = context.read<ThemeProvider>();
    final colors = theme.colors;

    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: 'Xóa Toàn Bộ Lịch Sử',
        icon: Icons.delete_sweep_rounded,
        isDark: theme.isDark,
        width: 440,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy', style: TextStyle(color: colors.textSecondary)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                TranslationHistory.clearHistory();
              });
              showAppToast(
                context,
                message: 'Đã xóa toàn bộ lịch sử!',
                icon: Icons.check_circle_outline_rounded,
                accentColor: colors.accentEmerald,
              );
            },
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Xác Nhận Xóa'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentRose,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        child: Text(
          'Bạn có chắc chắn muốn xóa toàn bộ lịch sử dịch không? Thao tác này không thể hoàn tác.',
          style: TextStyle(fontSize: 13, color: colors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final colors = theme.colors;

    final records = _filteredRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Bar & Filter Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.subCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.subCardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: colors.accentCyan),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: lang.t('history_search_hint'),
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  color: colors.textMuted,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              const SizedBox(width: 8),

              // Toggle Only Saved Filter Chip
              InkWell(
                onTap: () => setState(() => _onlySaved = !_onlySaved),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _onlySaved
                        ? colors.accentAmber.withValues(alpha: 0.2)
                        : colors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _onlySaved
                          ? colors.accentAmber
                          : colors.borderDefault.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _onlySaved
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 15,
                        color: _onlySaved
                            ? colors.accentAmber
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đã Lưu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              _onlySaved ? FontWeight.bold : FontWeight.w500,
                          color: _onlySaved
                              ? colors.accentAmber
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Clear All History Button
              if (TranslationHistory.records.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  color: colors.accentRose,
                  tooltip: lang.t('history_clear_all'),
                  onPressed: _clearAllHistory,
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Records List
        Expanded(
          child: records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: colors.textMuted.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lang.t('history_empty'),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = records[index];
                    return _buildRecordCard(item, colors, lang);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(
      TranslationRecord item, AppColors colors, LanguageProvider lang) {
    final timeStr =
        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} • ${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}';

    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  PillBadge(
                    label:
                        '${item.srcLang.toUpperCase()} → ${item.tgtLang.toUpperCase()}',
                    color: colors.accentCyan,
                    bg: colors.accentCyan.withValues(alpha: 0.15),
                    border: colors.accentCyan.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Restore button
                  Tooltip(
                    message: lang.t('history_restore'),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      color: colors.accentCyan,
                      onPressed: () {
                        if (widget.onRestoreText != null) {
                          widget.onRestoreText!(
                              item.text, item.srcLang, item.tgtLang);
                          showAppToast(
                            context,
                            message: 'Đã đưa vào khung dịch!',
                            icon: Icons.check_rounded,
                            accentColor: colors.accentEmerald,
                          );
                        }
                      },
                    ),
                  ),
                  // Copy button
                  Tooltip(
                    message: lang.t('btn_copy'),
                    child: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      color: colors.textSecondary,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: item.translated));
                        showAppToast(
                          context,
                          message: lang.t('toast_copied'),
                          icon: Icons.check_rounded,
                          accentColor: colors.accentEmerald,
                        );
                      },
                    ),
                  ),
                  // Star / Save button
                  IconButton(
                    icon: Icon(
                      item.isSaved
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 18,
                      color:
                          item.isSaved ? colors.accentAmber : colors.textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        TranslationHistory.toggleSave(item.id);
                      });
                    },
                  ),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: colors.textMuted,
                    onPressed: () {
                      setState(() {
                        TranslationHistory.deleteRecord(item.id);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Source text
          Text(
            item.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),

          // Translated text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Text(
              item.translated,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
