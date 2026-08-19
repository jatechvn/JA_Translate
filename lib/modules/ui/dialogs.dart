// lib/modules/ui/dialogs.dart
// Dialog components for Proxy config modal

import 'package:flutter/material.dart';
import '../app_config.dart';
import 'styles.dart';
import 'localization.dart';

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
    _hostController = TextEditingController(text: AppConfig.get('PROXY', 'host'));
    _portController = TextEditingController(text: AppConfig.get('PROXY', 'port'));
    _userController = TextEditingController(text: AppConfig.get('PROXY', 'user'));
    _passController = TextEditingController(text: AppConfig.get('PROXY', 'pass'));

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
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(8),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings_ethernet, color: c.linkAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      UiLocalizations.get('proxy_title', widget.uiLang),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Proxy toggle button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      UiLocalizations.get('proxy_enable', widget.uiLang),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.textSecondary),
                    ),
                    Switch(
                      value: _proxyEnabled,
                      activeColor: c.linkAccent,
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
                Text(UiLocalizations.get('proxy_host', widget.uiLang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
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
                Text(UiLocalizations.get('proxy_port', widget.uiLang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
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
                Text(UiLocalizations.get('proxy_user', widget.uiLang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
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
                Text(UiLocalizations.get('proxy_pass', widget.uiLang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  style: TextStyle(color: c.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Proxy authorization password',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(UiLocalizations.get('proxy_cancel', widget.uiLang)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isInputValid ? _saveSettings : null,
                      child: Text(UiLocalizations.get('proxy_save', widget.uiLang)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
