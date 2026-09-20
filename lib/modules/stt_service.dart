// lib/modules/stt_service.dart
// Speech-to-Text recording and transcription service

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';

class SttService {
  static final AudioRecorder _audioRecorder = AudioRecorder();
  static final ValueNotifier<bool> isRecording = ValueNotifier<bool>(false);
  static String? _currentAudioPath;

  /// Check if microphone permission is granted
  static Future<bool> hasPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (_) {
      return true; // Desktop platforms usually don't prompt runtime mic permission
    }
  }

  /// Start voice recording
  static Future<bool> startRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/stt_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentAudioPath = filePath;

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: filePath);
      isRecording.value = true;
      return true;
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
      isRecording.value = false;
      return false;
    }
  }

  /// Stop recording and transcribe the audio
  static Future<String?> stopRecordingAndTranscribe(
      {String targetLang = 'VN'}) async {
    try {
      if (!await _audioRecorder.isRecording()) {
        isRecording.value = false;
        return null;
      }

      final path = await _audioRecorder.stop();
      isRecording.value = false;
      final audioPath = path ?? _currentAudioPath;

      if (audioPath == null || !File(audioPath).existsSync()) {
        return null;
      }

      return await transcribe(audioPath, lang: targetLang);
    } catch (e) {
      debugPrint('Error stopping audio recording: $e');
      isRecording.value = false;
      return null;
    }
  }

  /// Transcribe audio file to text via Whisper API / Local Server
  static Future<String?> transcribe(String audioFilePath,
      {String lang = 'VN'}) async {
    final file = File(audioFilePath);
    if (!file.existsSync()) return null;

    final isLocal = AppConfig.isLocalAi;
    final apiBase = isLocal
        ? AppConfig.get('LOCAL_AI', 'endpoint',
            defaultValue: 'http://127.0.0.1:${AppConfig.localLlamaPort}/v1')
        : AppConfig.get('NVIDIA', 'api_base',
            defaultValue: 'https://integrate.api.nvidia.com/v1');
    final apiKey = isLocal ? '' : AppConfig.get('NVIDIA', 'api_key');

    final uri = Uri.parse('$apiBase/audio/transcriptions');

    try {
      final request = http.MultipartRequest('POST', uri);
      if (apiKey.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $apiKey';
      }
      request.fields['model'] = isLocal ? 'whisper' : 'openai/whisper-large-v3';
      request.files
          .add(await http.MultipartFile.fromPath('file', audioFilePath));

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        // Parse json response {"text": "..."}
        final match =
            RegExp(r'"text"\s*:\s*"([^"]+)"').firstMatch(responseBody);
        if (match != null) {
          return match.group(1)?.replaceAll(r'\n', '\n');
        }
        return responseBody.trim();
      }
    } catch (e) {
      debugPrint('Whisper transcription error: $e');
    }

    return null;
  }

  static void dispose() {
    _audioRecorder.dispose();
  }
}
