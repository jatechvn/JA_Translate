// lib/modules/ui/ota_settings_dialog.dart
// Dialog for configuring LAN OTA Update server, credentials, interval and manual check

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../ota_update_service.dart';
import 'styles.dart';
import 'localization.dart';
import 'glass_update_dialog.dart';

/// Mở hộp thoại cấu hình LAN OTA Update
Future<bool?> showOtaSettingsDialog({
  required BuildContext context,
  required String uiLang,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: OtaSettingsDialog(uiLang: uiLang),
    ),
  );
}

class OtaSettingsDialog extends StatefulWidget {
  final String uiLang;

  const OtaSettingsDialog({super.key, required this.uiLang});

  @override
  State<OtaSettingsDialog> createState() => _OtaSettingsDialogState();
}

class _OtaSettingsDialogState extends State<OtaSettingsDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _serverPathController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  String _selectedInterval = 'daily';
  bool _obscurePassword = true;

  bool _isLoading = true;
  bool _isChecking = false;
  String? _checkStatusMessage;
  bool _checkStatusIsSuccess = true;

  bool _isTestingConnection = false;
  String? _testConnectionResult;
  bool? _testConnectionSuccess;

  @override
  void initState() {
    super.initState();
    _serverPathController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _loadInitialConfig();
  }

  Future<void> _loadInitialConfig() async {
    final config = await OtaUpdateService().loadConfig();
    if (mounted) {
      setState(() {
        _serverPathController.text = config.serverPath;
        _usernameController.text = config.username;
        _passwordController.text = config.password;
        _selectedInterval = config.checkInterval;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _serverPathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig({bool closeOnSuccess = true}) async {
    final service = OtaUpdateService();
    final currentConfig = await service.loadConfig();
    final newConfig = currentConfig.copyWith(
      serverPath: _serverPathController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      checkInterval: _selectedInterval,
    );
    await service.saveConfig(newConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UiLocalizations.get('ota_saved_success', widget.uiLang),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      if (closeOnSuccess) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testConnectionResult = null;
      _testConnectionSuccess = null;
    });

    final path = _serverPathController.text.trim();
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();

    try {
      final success = await OtaUpdateService().connectSmbShare(
        path: path,
        username: user,
        password: pass,
      );
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _testConnectionSuccess = success;
          _testConnectionResult = success
              ? UiLocalizations.get('ota_connection_success', widget.uiLang)
              : UiLocalizations.get('ota_connection_failed', widget.uiLang);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _testConnectionSuccess = false;
          _testConnectionResult =
              '${UiLocalizations.get('ota_connection_failed', widget.uiLang)}: $e';
        });
      }
    }
  }

  void _openConfigFolder() {
    final file = OtaUpdateService().getConfigFile();
    if (Platform.isWindows) {
      if (file.existsSync()) {
        Process.run('explorer.exe', ['/select,', file.path]);
      } else {
        Process.run('explorer.exe', [file.parent.path]);
      }
    }
  }

  Future<void> _checkNow() async {
    setState(() {
      _isChecking = true;
      _checkStatusMessage = UiLocalizations.get('ota_checking', widget.uiLang);
      _checkStatusIsSuccess = true;
    });

    // Tự động lưu cấu hình mới nhất trước khi kiểm tra
    await _saveConfig(closeOnSuccess: false);

    final service = OtaUpdateService();
    final result = await service.checkForUpdates(
      overrideServerPath: _serverPathController.text.trim(),
      isManual: true,
    );

    if (!mounted) return;

    setState(() {
      _isChecking = false;
    });

    if (!result.isConnectionSuccess || result.errorMessage != null) {
      setState(() {
        _checkStatusIsSuccess = false;
        _checkStatusMessage =
            result.errorMessage ?? 'Không thể kết nối máy chủ';
      });
      return;
    }

    if (result.hasUpdate && result.packageInfo != null) {
      setState(() {
        _checkStatusIsSuccess = true;
        _checkStatusMessage =
            '${UiLocalizations.get('ota_update_available', widget.uiLang)}: ${result.packageInfo!.version.displayVersion}';
      });

      // Mở ngay hộp thoại GlassUpdateDialog
      if (mounted) {
        await showGlassUpdateDialog(
          context: context,
          packageInfo: result.packageInfo!,
          uiLang: widget.uiLang,
        );
      }
    } else {
      setState(() {
        _checkStatusIsSuccess = true;
        _checkStatusMessage =
            UiLocalizations.get('ota_up_to_date', widget.uiLang);
      });
    }
  }

  Widget _buildOtaIntervalChip({
    required String value,
    required String label,
    required IconData icon,
    required AppColors c,
  }) {
    final isSelected = _selectedInterval == value;
    final color = isSelected ? c.linkAccent : c.textSecondary;

    return InkWell(
      key: ValueKey('ota-interval-chip-$value'),
      onTap: () {
        setState(() => _selectedInterval = value);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? c.linkAccent.withOpacity(0.15)
              : c.bgTertiary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? c.linkAccent : c.borderDefault.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    if (_isLoading) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          borderColor: c.borderDefault,
          child: const SizedBox(
            width: 480,
            height: 240,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        borderColor: c.borderDefault,
        child: SizedBox(
          width: 520,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          BorderSide(color: c.borderDefault.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: c.linkAccent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: c.linkAccent.withOpacity(0.35)),
                        ),
                        child: Icon(
                          Icons.system_update_alt_rounded,
                          color: c.linkAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              UiLocalizations.get('ota_title', widget.uiLang),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${UiLocalizations.get('ota_current_version', widget.uiLang)} v$appVersion',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: c.bgTertiary.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: c.borderDefault.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Server Path
                      Text(
                        UiLocalizations.get('ota_server_path', widget.uiLang),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _serverPathController,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textPrimary,
                          fontFamily: 'Consolas, monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: UiLocalizations.get(
                              'ota_server_path_hint', widget.uiLang),
                          hintStyle:
                              TextStyle(fontSize: 11, color: c.textMuted),
                          isDense: true,
                          filled: true,
                          fillColor: c.bgTertiary.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: c.borderDefault.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: c.borderDefault.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: c.linkAccent),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          prefixIcon: Icon(
                            Icons.folder_shared_outlined,
                            size: 18,
                            color: c.linkAccent,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Username and Password
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  UiLocalizations.get(
                                      'ota_username', widget.uiLang),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: c.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _usernameController,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: c.bgTertiary.withOpacity(0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: c.borderDefault.withOpacity(0.3),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: c.textMuted,
                                    ),
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
                                Text(
                                  UiLocalizations.get(
                                      'ota_password', widget.uiLang),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: c.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: c.bgTertiary.withOpacity(0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: c.borderDefault.withOpacity(0.3),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      size: 16,
                                      color: c.textMuted,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 16,
                                        color: c.textMuted,
                                      ),
                                      splashRadius: 14,
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Auto-check interval with Quick Selection Chips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UiLocalizations.get('ota_interval', widget.uiLang),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            key: const ValueKey('ota-interval-chips'),
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildOtaIntervalChip(
                                value: 'daily',
                                label: UiLocalizations.get(
                                    'ota_interval_daily', widget.uiLang),
                                icon: Icons.today_rounded,
                                c: c,
                              ),
                              _buildOtaIntervalChip(
                                value: 'weekly',
                                label: UiLocalizations.get(
                                    'ota_interval_weekly', widget.uiLang),
                                icon: Icons.date_range_rounded,
                                c: c,
                              ),
                              _buildOtaIntervalChip(
                                value: 'monthly',
                                label: UiLocalizations.get(
                                    'ota_interval_monthly', widget.uiLang),
                                icon: Icons.calendar_month_rounded,
                                c: c,
                              ),
                              _buildOtaIntervalChip(
                                value: 'off',
                                label: UiLocalizations.get(
                                    'ota_interval_off', widget.uiLang),
                                icon: Icons.cancel_outlined,
                                c: c,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Action buttons: Test connection & Open config folder
                      Row(
                        children: [
                          OutlinedButton.icon(
                            key: const ValueKey('ota-test-connection-button'),
                            onPressed:
                                _isTestingConnection ? null : _testConnection,
                            icon: _isTestingConnection
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.wifi_find_rounded, size: 14),
                            label: Text(
                              _isTestingConnection
                                  ? UiLocalizations.get(
                                      'ota_testing_connection', widget.uiLang)
                                  : UiLocalizations.get(
                                      'ota_test_connection', widget.uiLang),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              side: BorderSide(
                                color: c.borderDefault.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            key:
                                const ValueKey('ota-open-config-folder-button'),
                            onPressed: _openConfigFolder,
                            icon:
                                const Icon(Icons.folder_open_rounded, size: 14),
                            label: Text(
                              UiLocalizations.get(
                                  'ota_open_config_folder', widget.uiLang),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              side: BorderSide(
                                color: c.borderDefault.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),

                      // Connection test feedback message if any
                      if (_testConnectionResult != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (_testConnectionSuccess == true
                                    ? c.statusActive
                                    : c.statusRemoved)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (_testConnectionSuccess == true
                                      ? c.statusActive
                                      : c.statusRemoved)
                                  .withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _testConnectionSuccess == true
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.error_outline_rounded,
                                size: 14,
                                color: _testConnectionSuccess == true
                                    ? c.statusActive
                                    : c.statusRemoved,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _testConnectionResult!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _testConnectionSuccess == true
                                        ? c.statusActive
                                        : c.statusRemoved,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Check Now button
                      OutlinedButton.icon(
                        key: const ValueKey('btn-ota-check-now'),
                        onPressed: _isChecking ? null : _checkNow,
                        icon: _isChecking
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: c.linkAccent,
                              ),
                        label: Text(
                          _isChecking
                              ? UiLocalizations.get(
                                  'ota_checking', widget.uiLang)
                              : UiLocalizations.get(
                                  'ota_check_now', widget.uiLang),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.linkAccent,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side:
                              BorderSide(color: c.linkAccent.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      // Status feedback message if any
                      if (_checkStatusMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: (_checkStatusIsSuccess
                                    ? c.statusActive
                                    : c.statusRemoved)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (_checkStatusIsSuccess
                                      ? c.statusActive
                                      : c.statusRemoved)
                                  .withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _checkStatusIsSuccess
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.error_outline_rounded,
                                size: 16,
                                color: _checkStatusIsSuccess
                                    ? c.statusActive
                                    : c.statusRemoved,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _checkStatusMessage!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _checkStatusIsSuccess
                                        ? c.statusActive
                                        : c.statusRemoved,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 3. Footer Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: c.borderDefault.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          UiLocalizations.get('clear', widget.uiLang) == 'XÓA'
                              ? 'Đóng'
                              : (widget.uiLang == 'CN' ? '关闭' : 'Close'),
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        key: const ValueKey('btn-ota-save'),
                        onPressed: () => _saveConfig(closeOnSuccess: true),
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: Text(
                          UiLocalizations.get('ota_save', widget.uiLang),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.linkAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
