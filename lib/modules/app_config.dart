// lib/modules/app_config.dart
// INI-style config file reader/writer with support for [sections]

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class AppConfig {
  static String? _configPath;
  static final Map<String, Map<String, String>> _sections = {};
  static bool enableTransparency = true;

  /// Initialize and load config from disk.
  /// Creates config.ini with defaults if it doesn't exist.
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        _configPath = p.join(Directory.current.path, 'config.ini');
      } else {
        final exeDir = p.dirname(Platform.resolvedExecutable);
        _configPath = p.join(exeDir, 'config.ini');
      }
      await _load();
    } catch (_) {
      _configPath = 'config.ini';
      await _load();
    }

    final transparencyStr =
        get('SETTINGS', 'enable_transparency', defaultValue: 'true');
    enableTransparency = transparencyStr == 'true';
    if (_sections['SETTINGS']?['enable_transparency'] == null) {
      await set('SETTINGS', 'enable_transparency', transparencyStr);
    }
  }

  static bool _isWindows11OrNewer() {
    if (!Platform.isWindows) return false;
    try {
      final versionStr = Platform.operatingSystemVersion;
      final match = RegExp(r'Build\s+(\d+)').firstMatch(versionStr);
      if (match != null) {
        final buildNumber = int.tryParse(match.group(1) ?? '') ?? 0;
        return buildNumber >= 22000;
      }
    } catch (_) {}
    return false;
  }

  static bool get isWindows11 => _isWindows11OrNewer();

  static Future<void> _load() async {
    try {
      final file = File(_configPath!);
      if (!file.existsSync()) {
        _initializeDefaults();
        await _save();
        return;
      }

      _sections.clear();
      final lines = file.readAsLinesSync();
      String currentSection = 'default';

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty ||
            trimmed.startsWith('#') ||
            trimmed.startsWith(';')) {
          continue;
        }

        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          currentSection = trimmed.substring(1, trimmed.length - 1).trim();
          continue;
        }

        final eqIdx = trimmed.indexOf('=');
        if (eqIdx > 0) {
          final key = trimmed.substring(0, eqIdx).trim();
          final value = trimmed.substring(eqIdx + 1).trim();

          if (!_sections.containsKey(currentSection)) {
            _sections[currentSection] = {};
          }
          _sections[currentSection]![key] = value;
        }
      }

      // Fill missing defaults
      _fillMissingDefaults();
    } catch (_) {
      _initializeDefaults();
    }
  }

  static void _initializeDefaults() {
    _sections.clear();
    _sections['NVIDIA'] = {
      'api_key': '',
      'api_base': 'https://integrate.api.nvidia.com/v1',
      'model': 'qwen/qwen2.5-7b-instruct',
      'vision_model': 'meta/llama-3.2-11b-vision-instruct',
    };
    _sections['LOCAL_AI'] = {
      'engine': 'llama_cpp',
      'gguf_model': 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      'llama_port': '8080',
      'threads': '4',
      'provider': 'llama_cpp',
      'endpoint': 'http://127.0.0.1:8080/v1',
      'model': 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      'temperature': '0.2',
    };
    _sections['SETTINGS'] = {
      'auto_translate_delay': '15',
      'default_target_lang': 'VN',
      'theme': 'dark',
      'ui_lang': 'VN',
      'active_provider': 'cloud',
      'enable_transparency': 'true',
    };
    _sections['PROXY'] = {
      'enabled': 'false',
      'host': '',
      'port': '',
      'user': '',
      'pass': '',
    };
  }

  static void _fillMissingDefaults() {
    if (!_sections.containsKey('NVIDIA')) _sections['NVIDIA'] = {};
    _sections['NVIDIA']!.putIfAbsent('api_key', () => '');
    _sections['NVIDIA']!
        .putIfAbsent('api_base', () => 'https://integrate.api.nvidia.com/v1');
    _sections['NVIDIA']!.putIfAbsent('model', () => 'qwen/qwen2.5-7b-instruct');
    _sections['NVIDIA']!.putIfAbsent(
        'vision_model', () => 'meta/llama-3.2-11b-vision-instruct');

    // Upgrade old defaults if present
    if (_sections['NVIDIA']?['model'] == 'google/gemma-4-31b-it') {
      _sections['NVIDIA']!['model'] = 'qwen/qwen2.5-7b-instruct';
    }
    if (_sections['NVIDIA']?['vision_model'] ==
        'meta/llama-3.2-90b-vision-instruct') {
      _sections['NVIDIA']!['vision_model'] =
          'meta/llama-3.2-11b-vision-instruct';
    }

    if (!_sections.containsKey('LOCAL_AI')) _sections['LOCAL_AI'] = {};
    _sections['LOCAL_AI']!.putIfAbsent('engine', () => 'llama_cpp');
    _sections['LOCAL_AI']!
        .putIfAbsent('gguf_model', () => 'qwen2.5-1.5b-instruct-q4_k_m.gguf');
    _sections['LOCAL_AI']!.putIfAbsent('llama_port', () => '8080');
    _sections['LOCAL_AI']!.putIfAbsent('threads', () => '4');
    _sections['LOCAL_AI']!.putIfAbsent('provider', () => 'llama_cpp');
    _sections['LOCAL_AI']!
        .putIfAbsent('endpoint', () => 'http://127.0.0.1:8080/v1');
    _sections['LOCAL_AI']!
        .putIfAbsent('model', () => 'qwen2.5-1.5b-instruct-q4_k_m.gguf');
    _sections['LOCAL_AI']!.putIfAbsent('temperature', () => '0.2');

    if (!_sections.containsKey('SETTINGS')) _sections['SETTINGS'] = {};
    _sections['SETTINGS']!.putIfAbsent('auto_translate_delay', () => '15');
    _sections['SETTINGS']!.putIfAbsent('default_target_lang', () => 'VN');
    _sections['SETTINGS']!.putIfAbsent('theme', () => 'dark');
    _sections['SETTINGS']!.putIfAbsent('ui_lang', () => 'VN');
    _sections['SETTINGS']!.putIfAbsent('active_provider', () => 'cloud');
    _sections['SETTINGS']!.putIfAbsent('enable_transparency', () => 'true');

    if (!_sections.containsKey('PROXY')) _sections['PROXY'] = {};
    _sections['PROXY']!.putIfAbsent('enabled', () => 'false');
    _sections['PROXY']!.putIfAbsent('host', () => '');
    _sections['PROXY']!.putIfAbsent('port', () => '');
    _sections['PROXY']!.putIfAbsent('user', () => '');
    _sections['PROXY']!.putIfAbsent('pass', () => '');
  }

  static bool get isLocalAi =>
      get('SETTINGS', 'active_provider', defaultValue: 'cloud') == 'local';
  static String get activeProvider =>
      get('SETTINGS', 'active_provider', defaultValue: 'cloud');
  static String get localEngine =>
      get('LOCAL_AI', 'engine', defaultValue: 'llama_cpp');
  static String get localGgufModel => get('LOCAL_AI', 'gguf_model',
      defaultValue: 'qwen2.5-1.5b-instruct-q4_k_m.gguf');
  static int get localLlamaPort =>
      int.tryParse(get('LOCAL_AI', 'llama_port', defaultValue: '8080')) ?? 8080;
  static int get localThreads =>
      int.tryParse(get('LOCAL_AI', 'threads', defaultValue: '4')) ?? 4;
  static Future<void> setActiveProvider(String provider) async {
    await set('SETTINGS', 'active_provider', provider);
  }

  static Future<void> _save() async {
    try {
      if (_configPath == null) return;
      final file = File(_configPath!);
      final parent = file.parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }
      final buffer = StringBuffer();

      _sections.forEach((section, keys) {
        buffer.writeln('[$section]');
        keys.forEach((key, val) {
          buffer.writeln('$key = $val');
        });
        buffer.writeln();
      });

      file.writeAsStringSync(buffer.toString());
    } catch (_) {}
  }

  /// Get config value
  static String get(String section, String key, {String defaultValue = ''}) {
    return _sections[section]?[key] ?? defaultValue;
  }

  /// Set config value and save
  static Future<void> set(String section, String key, String value) async {
    if (!_sections.containsKey(section)) {
      _sections[section] = {};
    }
    _sections[section]![key] = value;
    await _save();
  }
}
