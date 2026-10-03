// test/ota_update_service_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/modules/ota_update_service.dart';

void main() {
  group('SemanticVersion parsing and comparisons', () {
    test('parses standard 3-part version', () {
      final v = SemanticVersion.tryParse('1.2.3');
      expect(v, isNotNull);
      expect(v!.major, equals(1));
      expect(v.minor, equals(2));
      expect(v.patch, equals(3));
      expect(v.build, isNull);
      expect(v.displayVersion, equals('v1.2.3'));
    });

    test('parses version with v prefix', () {
      final v = SemanticVersion.tryParse('v1.1.0');
      expect(v, isNotNull);
      expect(v!.major, equals(1));
      expect(v.minor, equals(1));
      expect(v.patch, equals(0));
    });

    test('parses version with build number', () {
      final v = SemanticVersion.tryParse('1.1.0+2');
      expect(v, isNotNull);
      expect(v!.major, equals(1));
      expect(v.minor, equals(1));
      expect(v.patch, equals(0));
      expect(v.build, equals(2));
    });

    test('parses version with prerelease tag', () {
      final v = SemanticVersion.tryParse('2.0.0-beta.1');
      expect(v, isNotNull);
      expect(v!.major, equals(2));
      expect(v.minor, equals(0));
      expect(v.patch, equals(0));
      expect(v.prerelease, equals('beta.1'));
    });

    test('correctly compares versions', () {
      final v100 = SemanticVersion.tryParse('1.0.0')!;
      final v110 = SemanticVersion.tryParse('1.1.0')!;
      final v111 = SemanticVersion.tryParse('1.1.1')!;
      final v110b2 = SemanticVersion.tryParse('1.1.0+2')!;
      final v200 = SemanticVersion.tryParse('2.0.0')!;

      expect(v110 > v100, isTrue);
      expect(v111 > v110, isTrue);
      expect(v110b2 > v110, isTrue);
      expect(v200 > v111, isTrue);
      expect(v100 < v110, isTrue);
      expect(v110 == SemanticVersion.tryParse('v1.1.0'), isTrue);
    });

    test('returns null for invalid inputs', () {
      expect(SemanticVersion.tryParse(''), isNull);
      expect(SemanticVersion.tryParse('abc'), isNull);
      expect(SemanticVersion.tryParse('1.2.3.4.5'), isNull);
    });
  });

  group('OtaUpdateService helper tests', () {
    test('isValidPackageName validates correct names', () {
      expect(
        OtaUpdateService.isValidPackageName(
            'JA_Translate_v1.1.0_Windows_x64.zip'),
        isTrue,
      );
      expect(
        OtaUpdateService.isValidPackageName('JA_Translate_1.2.0.zip'),
        isTrue,
      );
      expect(
        OtaUpdateService.isValidPackageName('JA_Translate_v1.1.0+2.zip'),
        isTrue,
      );
      expect(
        OtaUpdateService.isValidPackageName(
            'JA_Translate_v1.1.0_Windows_x64.exe'),
        isFalse,
      );
      expect(
        OtaUpdateService.isValidPackageName('../JA_Translate_v1.1.0.zip'),
        isFalse,
      );
      expect(
        OtaUpdateService.isValidPackageName('OtherApp_v1.1.0.zip'),
        isFalse,
      );
    });

    test('extractSmbShareRoot extracts valid UNC share root', () {
      expect(
        OtaUpdateService.extractSmbShareRoot(
            r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Translate'),
        equals(r'\\10.81.141.226\temp'),
      );
      expect(
        OtaUpdateService.extractSmbShareRoot('//192.168.1.100/shared/updates'),
        equals(r'\\192.168.1.100\shared'),
      );
      expect(
        OtaUpdateService.extractSmbShareRoot(r'C:\local\folder'),
        isNull,
      );
    });

    test('shouldCheckForUpdates respects interval', () {
      final service = OtaUpdateService();
      final now = DateTime(2026, 9, 21, 12, 0);

      // 'off' is always false
      expect(
        service.shouldCheckForUpdates(
          interval: 'off',
          lastCheckTime: null,
          now: now,
        ),
        isFalse,
      );

      // null lastCheckTime is always true if not 'off'
      expect(
        service.shouldCheckForUpdates(
          interval: 'daily',
          lastCheckTime: null,
          now: now,
        ),
        isTrue,
      );

      // daily interval
      expect(
        service.shouldCheckForUpdates(
          interval: 'daily',
          lastCheckTime: now.subtract(const Duration(hours: 23)),
          now: now,
        ),
        isFalse,
      );
      expect(
        service.shouldCheckForUpdates(
          interval: 'daily',
          lastCheckTime: now.subtract(const Duration(hours: 25)),
          now: now,
        ),
        isTrue,
      );

      // weekly interval
      expect(
        service.shouldCheckForUpdates(
          interval: 'weekly',
          lastCheckTime: now.subtract(const Duration(days: 6)),
          now: now,
        ),
        isFalse,
      );
      expect(
        service.shouldCheckForUpdates(
          interval: 'weekly',
          lastCheckTime: now.subtract(const Duration(days: 8)),
          now: now,
        ),
        isTrue,
      );
    });

    test('generateApplyUpdateScript contains correct commands and exclusions',
        () {
      final script = OtaUpdateService.generateApplyUpdateScript(
        oldPid: 12345,
        sourceDir: r'C:\Temp\Extract',
        targetDir: r'C:\Program Files\JA_Translate',
        exeName: 'ja_translate.exe',
      );

      expect(script, contains('set "OLD_PID=12345"'));
      expect(script, contains(r'set "SRC_DIR=C:\Temp\Extract"'));
      expect(script, contains(r'set "DST_DIR=C:\Program Files\JA_Translate"'));
      expect(script, contains('set "EXE_NAME=ja_translate.exe"'));
      // Verifies robocopy exclusions
      expect(
        script,
        contains(
            r'/XD logs models backups backup /XF config.ini update_config.json translation_cache.json translation_history.json'),
      );
      // Verifies wait loop and start command
      expect(script, contains('tasklist /fi "PID eq %OLD_PID%"'));
      expect(script, contains('start "" "%DST_DIR%\\%EXE_NAME%"'));
      expect(script, contains(':rollback'));
    });
  });

  group('OtaUpdateConfig serialization', () {
    test('toJson and fromJson preserves data', () {
      final config = OtaUpdateConfig(
        serverPath: r'\\server\share\ja',
        username: 'admin',
        password: 'secret',
        checkInterval: 'weekly',
        autoDownload: true,
        lastCheckTime: DateTime(2026, 9, 21, 10, 0),
        cachedUpdateVersion: '1.2.0',
      );

      final json = config.toJson();
      final decoded = OtaUpdateConfig.fromJson(json);

      expect(decoded.serverPath, equals(config.serverPath));
      expect(decoded.username, equals(config.username));
      expect(decoded.password, equals(config.password));
      expect(decoded.checkInterval, equals(config.checkInterval));
      expect(decoded.autoDownload, equals(config.autoDownload));
      expect(decoded.lastCheckTime, equals(config.lastCheckTime));
      expect(decoded.cachedUpdateVersion, equals(config.cachedUpdateVersion));
    });
  });

  group('OtaUpdateService directory scanning and update check', () {
    late Directory tempServerDir;
    late Directory tempClientDir;

    setUp(() async {
      tempServerDir =
          await Directory.systemTemp.createTemp('ja_ota_server_test_');
      tempClientDir =
          await Directory.systemTemp.createTemp('ja_ota_client_test_');
      final configFile = File('${tempClientDir.path}/update_config.json');
      await configFile.writeAsString('{}');
      OtaUpdateService().setCustomConfigFileForTesting(configFile);
      OtaUpdateService().setCustomServerDirForTesting(tempServerDir);
    });

    tearDown(() async {
      OtaUpdateService().setCustomConfigFileForTesting(null);
      OtaUpdateService().setCustomServerDirForTesting(null);
      try {
        await tempServerDir.delete(recursive: true);
      } catch (_) {}
      try {
        await tempClientDir.delete(recursive: true);
      } catch (_) {}
    });

    test('detects newer version from version.json', () async {
      final zipFile =
          File('${tempServerDir.path}/JA_Translate_v1.2.0_Windows_x64.zip');
      await zipFile.writeAsString('test package content');

      final versionJson = File('${tempServerDir.path}/version.json');
      await versionJson.writeAsString('''
{
  "version": "1.2.0",
  "fileName": "JA_Translate_v1.2.0_Windows_x64.zip",
  "releaseNotes": "Bug fixes and improvements",
  "releaseDate": "2026-09-21T00:00:00.000Z"
}
''');

      final service = OtaUpdateService();
      final result = await service.checkForUpdates(
        overrideServerPath: tempServerDir.path,
        overrideCurrentVersion: '1.1.0',
        isManual: true,
      );

      expect(result.isConnectionSuccess, isTrue);
      expect(result.hasUpdate, isTrue);
      expect(result.packageInfo, isNotNull);
      expect(result.packageInfo!.version.toString(), equals('1.2.0'));
      expect(result.packageInfo!.releaseNotes,
          equals('Bug fixes and improvements'));
    });

    test('scans zip files when version.json is absent', () async {
      final zipFile =
          File('${tempServerDir.path}/JA_Translate_v1.3.0_Windows_x64.zip');
      await zipFile.writeAsString('test package zip');

      final service = OtaUpdateService();
      final result = await service.checkForUpdates(
        overrideServerPath: tempServerDir.path,
        overrideCurrentVersion: '1.1.0',
        isManual: true,
      );

      expect(result.isConnectionSuccess, isTrue);
      expect(result.hasUpdate, isTrue);
      expect(result.packageInfo, isNotNull);
      expect(result.packageInfo!.version.toString(), equals('1.3.0'));
    });

    test('reports no update when current version is equal or newer', () async {
      final zipFile =
          File('${tempServerDir.path}/JA_Translate_v1.1.0_Windows_x64.zip');
      await zipFile.writeAsString('test package zip');

      final service = OtaUpdateService();
      final result = await service.checkForUpdates(
        overrideServerPath: tempServerDir.path,
        overrideCurrentVersion: '1.1.0',
        isManual: true,
      );

      expect(result.isConnectionSuccess, isTrue);
      expect(result.hasUpdate, isFalse);
    });

    test(
        'detects newer version from zip files even when version.json has older version',
        () async {
      // Simulate version.json being stale at 1.2.1
      final v121Zip =
          File('${tempServerDir.path}/JA_Translate_v1.2.1_Windows_x64.zip');
      await v121Zip.writeAsString('v121 zip');
      final versionJson = File('${tempServerDir.path}/version.json');
      await versionJson.writeAsString('''
{
  "version": "1.2.1",
  "fileName": "JA_Translate_v1.2.1_Windows_x64.zip",
  "releaseNotes": "Stale 1.2.1 release notes",
  "releaseDate": "2026-10-02T10:00:00.000Z"
}
''');

      // But a newer v1.2.3 zip is uploaded
      final v123Zip =
          File('${tempServerDir.path}/JA_Translate_v1.2.3_Windows_x64.zip');
      await v123Zip.writeAsString('v123 zip');

      final service = OtaUpdateService();
      final result = await service.checkForUpdates(
        overrideServerPath: tempServerDir.path,
        overrideCurrentVersion: '1.2.1',
        isManual: true,
      );

      expect(result.isConnectionSuccess, isTrue);
      expect(result.hasUpdate, isTrue);
      expect(result.packageInfo, isNotNull);
      expect(result.packageInfo!.version.toString(), equals('1.2.3'));
      expect(result.packageInfo!.fileName,
          equals('JA_Translate_v1.2.3_Windows_x64.zip'));
    });
  });
}
