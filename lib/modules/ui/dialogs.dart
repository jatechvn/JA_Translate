// lib/modules/ui/dialogs.dart
// Dialog components for Proxy config modal

import 'dart:async';
import 'package:flutter/material.dart';
import '../app_config.dart';
import '../api_client.dart';
import '../llama_service.dart';
import 'styles.dart';
import 'localization.dart';
import 'glass_dropdown.dart';

class ProxyDialog extends StatefulWidget {
  final String uiLang;
  const ProxyDialog({super.key, required this.uiLang});

  @override
  State<ProxyDialog> createState() => _ProxyDialogState();
}

class _ProxyDialogState extends State<ProxyDialog> {
  final _formKey = GlobalKey<FormState>();

  late bool _proxyEnabled;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _userController;
  late final TextEditingController _passController;

  @override
  void initState() {
    super.initState();
    _proxyEnabled = AppConfig.get('PROXY', 'enabled') == 'true';
    _hostController =
        TextEditingController(text: AppConfig.get('PROXY', 'host'));
    _portController =
        TextEditingController(text: AppConfig.get('PROXY', 'port'));
    _userController =
        TextEditingController(text: AppConfig.get('PROXY', 'user'));
    _passController =
        TextEditingController(text: AppConfig.get('PROXY', 'pass'));

    // Monitor changes to validate active capabilities dynamically
    _hostController.addListener(_validateInputs);
    _portController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  bool get _isInputValid {
    final host = _hostController.text.trim();
    final port = _portController.text.trim();
    return host.isNotEmpty && port.isNotEmpty;
  }

  void _validateInputs() {
    setState(() {
      if (!_isInputValid) {
        _proxyEnabled = false;
      }
    });
  }

  void _saveSettings() async {
    if (!_isInputValid) return;

    await AppConfig.set('PROXY', 'enabled', _proxyEnabled.toString());
    await AppConfig.set('PROXY', 'host', _hostController.text.trim());
    await AppConfig.set('PROXY', 'port', _portController.text.trim());
    await AppConfig.set('PROXY', 'user', _userController.text.trim());
    await AppConfig.set('PROXY', 'pass', _passController.text.trim());

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        borderColor: c.borderDefault,
        child: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. FIXED HEADER
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
                      Icon(Icons.settings_ethernet,
                          color: c.linkAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          UiLocalizations.get('proxy_title', widget.uiLang),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Isolated Glass Close Button
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
                                  color: c.borderDefault.withOpacity(0.3)),
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 18, color: c.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. BODY CONTENT
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Proxy toggle button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            UiLocalizations.get('proxy_enable', widget.uiLang),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: c.textSecondary),
                          ),
                          Switch(
                            value: _proxyEnabled,
                            activeThumbColor: c.linkAccent,
                            onChanged: _isInputValid
                                ? (value) {
                                    setState(() {
                                      _proxyEnabled = value;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Host input
                      Text(UiLocalizations.get('proxy_host', widget.uiLang),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _hostController,
                        style: TextStyle(color: c.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 127.0.0.1 or proxy.example.com',
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Port input
                      Text(UiLocalizations.get('proxy_port', widget.uiLang),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _portController,
                        style: TextStyle(color: c.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 8080',
                        ),
                      ),
                      const SizedBox(height: 14),
                      // User input
                      Text(UiLocalizations.get('proxy_user', widget.uiLang),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _userController,
                        style: TextStyle(color: c.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Proxy authorization username',
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Password input
                      Text(UiLocalizations.get('proxy_pass', widget.uiLang),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passController,
                        obscureText: true,
                        style: TextStyle(color: c.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Proxy authorization password',
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. FIXED FOOTER
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: c.borderDefault.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                            UiLocalizations.get('proxy_cancel', widget.uiLang)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isInputValid ? _saveSettings : null,
                        child: Text(
                            UiLocalizations.get('proxy_save', widget.uiLang)),
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

class LocalAiDialog extends StatefulWidget {
  final String uiLang;
  const LocalAiDialog({super.key, required this.uiLang});

  @override
  State<LocalAiDialog> createState() => _LocalAiDialogState();
}

class _LocalAiDialogState extends State<LocalAiDialog> {
  // Llama.cpp state
  String _selectedGgufModel = '';
  List<String> _installedGgufModels = [];
  bool _isLoadingGguf = false;
  int _threads = 4;
  bool _isServerRunning = false;
  bool _isTogglingServer = false;

  // Download state
  bool _isDownloading = false;
  String _downloadingTarget = '';
  double _downloadPercent = 0.0;
  String _downloadStatus = '';
  String _downloadDetail = '';
  String? _downloadError;
  StreamSubscription? _downloadSub;

  @override
  void initState() {
    super.initState();
    _selectedGgufModel = AppConfig.localGgufModel;
    _threads = AppConfig.localThreads;
    _refreshGgufModels();
    _checkServerStatus();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> _checkServerStatus() async {
    final running =
        await LlamaService.isServerRunning(port: AppConfig.localLlamaPort);
    if (mounted) {
      setState(() => _isServerRunning = running);
    }
  }

  void _refreshGgufModels() {
    setState(() => _isLoadingGguf = true);
    final models = LlamaService.getInstalledGgufModels();
    setState(() {
      _installedGgufModels = models;
      _isLoadingGguf = false;
      if (_selectedGgufModel.isEmpty && models.isNotEmpty) {
        _selectedGgufModel = models.first;
      }
    });
  }

  Future<void> _toggleLlamaServer() async {
    setState(() => _isTogglingServer = true);
    if (_isServerRunning) {
      await LlamaService().stopServer();
    } else {
      await LlamaService().startServer(
        modelFileName:
            _selectedGgufModel.isNotEmpty ? _selectedGgufModel : null,
        port: AppConfig.localLlamaPort,
        threads: _threads,
      );
    }
    await _checkServerStatus();
    if (mounted) setState(() => _isTogglingServer = false);
  }

  Future<void> _startGgufDownload(LlamaModelPreset preset) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadingTarget = preset.name;
      _downloadPercent = 0.0;
      _downloadStatus = UiLocalizations.get('local_downloading', widget.uiLang);
      _downloadDetail = '';
      _downloadError = null;
    });

    _downloadSub = LlamaService.downloadModelStream(
      downloadUrl: preset.downloadUrl,
      fileName: preset.fileName,
    ).listen((event) {
      if (!mounted) return;
      final status = event['status']?.toString() ?? '';
      final percent = (event['percent'] as num?)?.toDouble() ?? 0.0;
      final completed = (event['completed'] as num?)?.toInt() ?? 0;
      final total = (event['total'] as num?)?.toInt() ?? 0;
      final done = event['done'] == true;
      final error = event['error']?.toString();

      setState(() {
        _downloadStatus =
            status == 'downloading' ? 'Đang tải vào models/...' : status;
        _downloadPercent = percent;
        if (total > 0) {
          final compMB = (completed / 1048576).toStringAsFixed(1);
          final totMB = (total / 1048576).toStringAsFixed(1);
          _downloadDetail =
              '$compMB MB / $totMB MB (${(percent * 100).toStringAsFixed(0)}%)';
        }
        if (error != null) {
          _downloadError = error;
          _isDownloading = false;
        } else if (done) {
          _isDownloading = false;
          _selectedGgufModel = preset.fileName;
          _refreshGgufModels();
        }
      });
    }, onError: (err) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadError = err.toString();
        });
      }
    });
  }

  Future<void> _saveSettings() async {
    await AppConfig.set('LOCAL_AI', 'engine', 'llama_cpp');
    await AppConfig.set('LOCAL_AI', 'provider', 'llama_cpp');
    await AppConfig.set('LOCAL_AI', 'gguf_model', _selectedGgufModel.trim());
    await AppConfig.set('LOCAL_AI', 'threads', _threads.toString());
    await AppConfig.set('LOCAL_AI', 'model', _selectedGgufModel.trim());
    await AppConfig.set('LOCAL_AI', 'endpoint',
        'http://127.0.0.1:${AppConfig.localLlamaPort}/v1');
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    final threadOptions = const [
      GlassDropdownItem<int>(
        value: 1,
        label: '1 Luồng CPU',
        subtitle: 'Tiết kiệm CPU, phù hợp chạy nền êm ái',
        badge: '1 Core',
      ),
      GlassDropdownItem<int>(
        value: 2,
        label: '2 Luồng CPU',
        subtitle: 'Cân bằng nhẹ, ít chiếm dụng tài nguyên',
        badge: '2 Cores',
      ),
      GlassDropdownItem<int>(
        value: 4,
        label: '4 Luồng CPU',
        subtitle: 'Cân bằng tối ưu tốc độ & RAM cho máy 8GB',
        badge: 'Khuyên dùng',
      ),
      GlassDropdownItem<int>(
        value: 6,
        label: '6 Luồng CPU',
        subtitle: 'Tối ưu chip 6 nhân 12 luồng trên Mini PC',
        badge: '6 Cores',
      ),
      GlassDropdownItem<int>(
        value: 8,
        label: '8 Luồng CPU',
        subtitle: 'Hiệu năng cao cho chip 8 nhân thực',
        badge: '8 Cores',
      ),
      GlassDropdownItem<int>(
        value: 12,
        label: '12 Luồng CPU',
        subtitle: 'Tốc độ dịch cực nhanh cho CPU đa luồng',
        badge: '12 Cores',
      ),
      GlassDropdownItem<int>(
        value: 16,
        label: '16 Luồng CPU',
        subtitle: 'Tối đa máy trạm / Desktop mạnh',
        badge: '16 Cores',
      ),
    ];

    final modelOptions = _installedGgufModels.map((m) {
      final preset =
          LlamaService.presets.where((p) => p.fileName == m).firstOrNull;
      return GlassDropdownItem<String>(
        value: m,
        label: preset?.name ?? m,
        subtitle: m,
        badge: preset?.sizeLabel ?? '.gguf',
        icon: Icons.psychology_outlined,
      );
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        borderColor: c.borderDefault,
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 740),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. FIXED HEADER (Không bị cuộn đi, tách biệt 100% khỏi scrollbar)
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: c.borderDefault.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.computer, color: c.targetAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  UiLocalizations.get(
                                      'local_ai_title', widget.uiLang),
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: c.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.targetAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: c.targetAccent.withOpacity(0.35)),
                                ),
                                child: Text(
                                  'AVX2 • Standalone',
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: c.targetAccent),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'AI Local độc lập chạy trực tiếp trong App • Tối ưu máy 8GB RAM • Không cần cài Ollama',
                            style:
                                TextStyle(fontSize: 11, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Dedicated Close Button with nice hover and hit-box
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        hoverColor: c.bgHover,
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: c.bgTertiary.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: c.borderDefault.withOpacity(0.3)),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: c.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. PINNED ACTIVE DOWNLOAD BANNER (Always visible if downloading, never hidden)
              if (_isDownloading)
                Container(
                  margin: const EdgeInsets.fromLTRB(18, 12, 18, 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: c.targetAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.targetAccent.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: c.targetAccent.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              value: _downloadPercent > 0
                                  ? _downloadPercent
                                  : null,
                              color: c.targetAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _downloadStatus.isNotEmpty
                                      ? '$_downloadStatus: $_downloadingTarget'
                                      : 'ĐANG TẢI MODEL: $_downloadingTarget',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: c.targetAccent),
                                ),
                                if (_downloadDetail.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _downloadDetail,
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: c.textSecondary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              _downloadSub?.cancel();
                              setState(() {
                                _isDownloading = false;
                                _downloadStatus = '';
                                _downloadDetail = '';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close,
                                      size: 12, color: Colors.red.shade300),
                                  const SizedBox(width: 4),
                                  Text('Hủy tải',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.red.shade300,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _downloadPercent > 0 ? _downloadPercent : null,
                          minHeight: 5,
                          backgroundColor: c.borderDefault.withOpacity(0.2),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(c.targetAccent),
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. SCROLLABLE BODY
              Flexible(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Server Status & Toggle
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: c.bgTertiary.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: c.borderDefault.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isServerRunning
                                      ? c.statusActive
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Llama Server: ${_isServerRunning ? UiLocalizations.get('local_server_running', widget.uiLang) : UiLocalizations.get('local_server_stopped', widget.uiLang)}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: _isServerRunning
                                            ? c.statusActive
                                            : c.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Port ${AppConfig.localLlamaPort} • Tự động khởi chạy ngầm khi dịch • Không chiếm GUI',
                                      style: TextStyle(
                                          fontSize: 10, color: c.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: _isTogglingServer
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: Colors.white))
                                    : Icon(
                                        _isServerRunning
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                        size: 14),
                                label: Text(
                                  _isServerRunning
                                      ? UiLocalizations.get(
                                          'local_stop_server', widget.uiLang)
                                      : UiLocalizations.get(
                                          'local_start_server', widget.uiLang),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isServerRunning
                                      ? Colors.red.shade700
                                      : c.targetAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: _isTogglingServer
                                    ? null
                                    : _toggleLlamaServer,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. Hardware: CPU Threads Dropdown
                        Text(
                          'Số luồng CPU (Threads) phân bổ:',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        GlassDropdown<int>(
                          items: threadOptions,
                          value: _threads,
                          colors: c,
                          hintText: 'Chọn số luồng CPU…',
                          enableSearch: false,
                          onChanged: (val) {
                            setState(() => _threads = val);
                          },
                        ),
                        const SizedBox(height: 14),

                        // 3. Models Folder Info & Open Folder
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: c.bgTertiary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: c.borderDefault.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.folder_special,
                                  size: 20, color: c.targetAccent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      UiLocalizations.get(
                                          'local_models_folder', widget.uiLang),
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: c.textPrimary),
                                    ),
                                    Text(
                                      LlamaService.getModelsDirectory(),
                                      style: TextStyle(
                                          fontSize: 10, color: c.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.folder_open, size: 14),
                                label: Text(
                                  UiLocalizations.get(
                                      'local_open_folder', widget.uiLang),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: LlamaService.openModelsFolder,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Installed GGUF models in app
                        Row(
                          children: [
                            Text(
                              UiLocalizations.get(
                                  'local_installed_models', widget.uiLang),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              icon: _isLoadingGguf
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5))
                                  : const Icon(Icons.refresh, size: 14),
                              label: Text(
                                  UiLocalizations.get(
                                      'local_scan_models', widget.uiLang),
                                  style: const TextStyle(fontSize: 11)),
                              onPressed:
                                  _isLoadingGguf ? null : _refreshGgufModels,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        if (_installedGgufModels.isNotEmpty) ...[
                          GlassDropdown<String>(
                            items: modelOptions,
                            value: _selectedGgufModel.isNotEmpty
                                ? _selectedGgufModel
                                : null,
                            colors: c,
                            hintText: 'Chọn model GGUF đang có…',
                            enableSearch: _installedGgufModels.length > 4,
                            onChanged: (val) {
                              setState(() => _selectedGgufModel = val);
                            },
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _installedGgufModels.map((m) {
                              final isSelected = _selectedGgufModel == m;
                              return ChoiceChip(
                                label: Text(m,
                                    style: const TextStyle(fontSize: 11)),
                                selected: isSelected,
                                selectedColor: c.targetAccent,
                                backgroundColor: c.bgTertiary,
                                labelStyle: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color:
                                      isSelected ? Colors.white : c.textPrimary,
                                ),
                                onSelected: (_) {
                                  setState(() => _selectedGgufModel = m);
                                },
                              );
                            }).toList(),
                          ),
                        ] else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.bgTertiary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: c.borderDefault.withOpacity(0.2)),
                            ),
                            child: Text(
                              'Chưa phát hiện file .gguf nào trong thư mục models/. Vui lòng bấm "Tải về" 1-Click bên dưới hoặc sao chép model của bạn vào thư mục models/.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: c.textMuted,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // 5. Recommended 1-Click Download Presets
                        Text(
                          'Tải Model GGUF trực tiếp vào App (1-Click):',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary),
                        ),
                        const SizedBox(height: 8),

                        Column(
                          children: LlamaService.presets.map((preset) {
                            final isInstalled =
                                _installedGgufModels.contains(preset.fileName);
                            final isSelected =
                                _selectedGgufModel == preset.fileName;
                            final isThisDownloading = _isDownloading &&
                                (_downloadingTarget == preset.name ||
                                    _downloadingTarget == preset.fileName);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: c.bgTertiary.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isThisDownloading
                                      ? c.linkAccent
                                      : (isSelected
                                          ? c.targetAccent
                                          : (isInstalled
                                              ? c.targetAccent.withOpacity(0.3)
                                              : c.borderDefault
                                                  .withOpacity(0.2))),
                                  width: isThisDownloading || isSelected
                                      ? 1.4
                                      : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    preset.name,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isSelected
                                                          ? c.targetAccent
                                                          : c.textPrimary,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: c.targetAccent
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    preset.sizeLabel,
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: c.targetAccent),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              preset.description,
                                              style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: c.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isThisDownloading)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: c.targetAccent
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: c.targetAccent
                                                    .withOpacity(0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 1.8,
                                                  value: _downloadPercent > 0
                                                      ? _downloadPercent
                                                      : null,
                                                  color: c.targetAccent,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${(_downloadPercent * 100).toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: c.targetAccent),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (isInstalled)
                                        OutlinedButton.icon(
                                          icon: Icon(
                                              isSelected
                                                  ? Icons.check
                                                  : Icons.touch_app,
                                              size: 13),
                                          label: Text(
                                              isSelected
                                                  ? 'Đang dùng'
                                                  : 'Chọn dùng',
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isSelected
                                                ? c.targetAccent
                                                : c.textPrimary,
                                            side: BorderSide(
                                                color: isSelected
                                                    ? c.targetAccent
                                                    : c.borderDefault),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 6),
                                            minimumSize: Size.zero,
                                          ),
                                          onPressed: () {
                                            setState(() => _selectedGgufModel =
                                                preset.fileName);
                                          },
                                        )
                                      else
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.cloud_download,
                                              size: 14),
                                          label: const Text('Tải về',
                                              style: TextStyle(fontSize: 11)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: c.targetAccent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                          ),
                                          onPressed: _isDownloading
                                              ? null
                                              : () =>
                                                  _startGgufDownload(preset),
                                        ),
                                    ],
                                  ),
                                  // Inline Progress Bar when this card is downloading
                                  if (isThisDownloading) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: _downloadPercent > 0
                                            ? _downloadPercent
                                            : null,
                                        minHeight: 4,
                                        backgroundColor:
                                            c.borderDefault.withOpacity(0.2),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                c.targetAccent),
                                      ),
                                    ),
                                    if (_downloadDetail.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        _downloadDetail,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: c.targetAccent,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        if (_downloadError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${UiLocalizations.get('local_download_fail', widget.uiLang)}: $_downloadError',
                            style: TextStyle(
                                fontSize: 11,
                                color: c.statusRemoved,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // 4. FIXED FOOTER (Luôn hiển thị ở đáy, không cần cuộn)
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: c.borderDefault.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                          UiLocalizations.get('proxy_cancel', widget.uiLang)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isDownloading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.targetAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                          UiLocalizations.get('proxy_save', widget.uiLang)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CloudAiDialog extends StatefulWidget {
  final String uiLang;
  const CloudAiDialog({super.key, required this.uiLang});

  @override
  State<CloudAiDialog> createState() => _CloudAiDialogState();
}

class _CloudAiDialogState extends State<CloudAiDialog> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _apiBaseController;
  late final TextEditingController _textModelController;
  late final TextEditingController _visionModelController;

  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool? _testSuccess;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _apiKeyController =
        TextEditingController(text: AppConfig.get('NVIDIA', 'api_key'));
    _apiBaseController = TextEditingController(
      text: AppConfig.get('NVIDIA', 'api_base',
          defaultValue: 'https://integrate.api.nvidia.com/v1'),
    );
    _textModelController = TextEditingController(
      text: AppConfig.get('NVIDIA', 'model',
          defaultValue: 'qwen/qwen2.5-7b-instruct'),
    );
    _visionModelController = TextEditingController(
      text: AppConfig.get('NVIDIA', 'vision_model',
          defaultValue: 'meta/llama-3.2-11b-vision-instruct'),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiBaseController.dispose();
    _textModelController.dispose();
    _visionModelController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testMessage = null;
    });

    final res = await ApiClient.testCloudConnection(
      apiKey: _apiKeyController.text.trim(),
      apiBase: _apiBaseController.text.trim(),
      model: _textModelController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = res['success'] == true;
        _testMessage = res['message']?.toString();
      });
    }
  }

  Future<void> _saveSettings() async {
    await AppConfig.set('NVIDIA', 'api_key', _apiKeyController.text.trim());
    await AppConfig.set('NVIDIA', 'api_base', _apiBaseController.text.trim());
    await AppConfig.set('NVIDIA', 'model', _textModelController.text.trim());
    await AppConfig.set(
        'NVIDIA', 'vision_model', _visionModelController.text.trim());
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        borderColor: c.borderDefault,
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. FIXED HEADER
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: c.borderDefault.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_outlined, color: c.linkAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UiLocalizations.get(
                                'cloud_ai_title', widget.uiLang),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'OpenAI-Compatible / NVIDIA NIM API',
                            style: TextStyle(fontSize: 11, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Isolated Glass Close Button
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
                                color: c.borderDefault.withOpacity(0.3)),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: c.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. SCROLLABLE BODY
              Flexible(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // API Key Field
                        Text(
                          UiLocalizations.get('cloud_api_key', widget.uiLang),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _apiKeyController,
                          obscureText: _obscureApiKey,
                          style: TextStyle(color: c.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'nvapi-xxx / sk-xxx',
                            prefixIcon: const Icon(Icons.key, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureApiKey
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                                color: c.textMuted,
                              ),
                              onPressed: () => setState(
                                  () => _obscureApiKey = !_obscureApiKey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // API Base URL Field
                        Text(
                          UiLocalizations.get('cloud_api_base', widget.uiLang),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _apiBaseController,
                          style: TextStyle(color: c.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'https://integrate.api.nvidia.com/v1',
                            prefixIcon: Icon(Icons.language, size: 18),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Provider Presets
                        Wrap(
                          spacing: 6,
                          children: [
                            ActionChip(
                              label: const Text('NVIDIA NIM'),
                              backgroundColor: c.bgTertiary,
                              labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: c.linkAccent,
                                  fontWeight: FontWeight.bold),
                              onPressed: () {
                                setState(() {
                                  _apiBaseController.text =
                                      'https://integrate.api.nvidia.com/v1';
                                  _textModelController.text =
                                      'qwen/qwen2.5-7b-instruct';
                                  _visionModelController.text =
                                      'meta/llama-3.2-11b-vision-instruct';
                                });
                              },
                            ),
                            ActionChip(
                              label: const Text('OpenAI'),
                              backgroundColor: c.bgTertiary,
                              labelStyle: TextStyle(
                                  fontSize: 11, color: c.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _apiBaseController.text =
                                      'https://api.openai.com/v1';
                                  _textModelController.text = 'gpt-4o-mini';
                                  _visionModelController.text = 'gpt-4o-mini';
                                });
                              },
                            ),
                            ActionChip(
                              label: const Text('Groq'),
                              backgroundColor: c.bgTertiary,
                              labelStyle: TextStyle(
                                  fontSize: 11, color: c.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _apiBaseController.text =
                                      'https://api.groq.com/openai/v1';
                                  _textModelController.text =
                                      'qwen/qwen-2.5-32b';
                                  _visionModelController.text =
                                      'llama-3.2-11b-vision-preview';
                                });
                              },
                            ),
                            ActionChip(
                              label: const Text('OpenRouter'),
                              backgroundColor: c.bgTertiary,
                              labelStyle: TextStyle(
                                  fontSize: 11, color: c.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _apiBaseController.text =
                                      'https://openrouter.ai/api/v1';
                                  _textModelController.text =
                                      'qwen/qwen-2.5-72b-instruct';
                                  _visionModelController.text =
                                      'qwen/qwen-2-vl-72b-instruct';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Text Model Field
                        Text(
                          UiLocalizations.get(
                              'cloud_text_model', widget.uiLang),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _textModelController,
                          style: TextStyle(color: c.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'qwen/qwen2.5-7b-instruct',
                            prefixIcon: Icon(Icons.translate, size: 18),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Text Model Presets
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              label: const Text('qwen2.5-7b (Khuyên dùng)'),
                              backgroundColor: c.targetAccent.withOpacity(0.15),
                              labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: c.targetAccent,
                                  fontWeight: FontWeight.bold),
                              onPressed: () => setState(() =>
                                  _textModelController.text =
                                      'qwen/qwen2.5-7b-instruct'),
                            ),
                            ActionChip(
                              label: const Text('qwen2.5-72b (Mạnh mẽ)'),
                              backgroundColor: c.bgTertiary,
                              labelStyle:
                                  TextStyle(fontSize: 11, color: c.linkAccent),
                              onPressed: () => setState(() =>
                                  _textModelController.text =
                                      'qwen/qwen2.5-72b-instruct'),
                            ),
                            ActionChip(
                              label: const Text('deepseek-r1'),
                              backgroundColor: c.bgTertiary,
                              labelStyle: TextStyle(
                                  fontSize: 11, color: c.textSecondary),
                              onPressed: () => setState(() =>
                                  _textModelController.text =
                                      'deepseek-ai/deepseek-r1'),
                            ),
                            ActionChip(
                              label: const Text('llama-3.3-70b'),
                              backgroundColor: c.bgTertiary,
                              labelStyle: TextStyle(
                                  fontSize: 11, color: c.textSecondary),
                              onPressed: () => setState(() =>
                                  _textModelController.text =
                                      'meta/llama-3.3-70b-instruct'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Vision Model Field
                        Text(
                          UiLocalizations.get(
                              'cloud_vision_model', widget.uiLang),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _visionModelController,
                          style: TextStyle(color: c.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'meta/llama-3.2-11b-vision-instruct',
                            prefixIcon: Icon(Icons.image_search, size: 18),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Vision Model Presets
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              label: const Text(
                                  'llama-3.2-11b-vision (NIM/Nhanh)'),
                              backgroundColor: c.targetAccent.withOpacity(0.15),
                              labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: c.targetAccent,
                                  fontWeight: FontWeight.bold),
                              onPressed: () => setState(() =>
                                  _visionModelController.text =
                                      'meta/llama-3.2-11b-vision-instruct'),
                            ),
                            ActionChip(
                              label: const Text('gpt-4o-mini (OpenAI)'),
                              backgroundColor: c.bgTertiary,
                              labelStyle:
                                  TextStyle(fontSize: 11, color: c.linkAccent),
                              onPressed: () => setState(() =>
                                  _visionModelController.text = 'gpt-4o-mini'),
                            ),
                            ActionChip(
                              label: const Text('qwen-2-vl-72b (OpenRouter)'),
                              backgroundColor: c.bgTertiary,
                              labelStyle: TextStyle(
                                  fontSize: 11, color: c.textSecondary),
                              onPressed: () => setState(() =>
                                  _visionModelController.text =
                                      'qwen/qwen-2-vl-72b-instruct'),
                            ),
                            ActionChip(
                              label: const Text('llama-3.2-90b-vision'),
                              backgroundColor: c.bgTertiary,
                              labelStyle: TextStyle(
                                  fontSize: 11, color: c.textSecondary),
                              onPressed: () => setState(() =>
                                  _visionModelController.text =
                                      'meta/llama-3.2-90b-vision-instruct'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Test Connection Row
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: _isTesting
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: c.linkAccent),
                                    )
                                  : Icon(Icons.wifi_tethering,
                                      size: 16, color: c.linkAccent),
                              label: Text(UiLocalizations.get(
                                  'cloud_test', widget.uiLang)),
                              onPressed: _isTesting ? null : _testConnection,
                            ),
                            const SizedBox(width: 12),
                            if (_testSuccess != null)
                              Expanded(
                                child: Text(
                                  _testSuccess == true
                                      ? UiLocalizations.get(
                                          'cloud_test_ok', widget.uiLang)
                                      : '${UiLocalizations.get('cloud_test_fail', widget.uiLang)}: $_testMessage',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _testSuccess == true
                                        ? c.statusActive
                                        : c.statusRemoved,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. FIXED FOOTER
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: c.borderDefault.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                          UiLocalizations.get('proxy_cancel', widget.uiLang)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.linkAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                          UiLocalizations.get('proxy_save', widget.uiLang)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
