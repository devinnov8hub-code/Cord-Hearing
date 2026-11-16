import 'dart:typed_data';

import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
import 'package:cord_hearing/src/core/services/chord_ota_service.dart';
import 'package:cord_hearing/src/core/services/firebase_ota_service.dart';
import 'package:cord_hearing/src/core/services/paired_devices_service.dart';
import 'package:cord_hearing/src/model/paired_device_record.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChordBleConstants', () {
    test('formats 3-byte binary firmware version 00 03 00 as 0.3.0', () {
      expect(
        ChordBleConstants.formatFirmwareVersion(const [0x00, 0x03, 0x00]),
        equals('0.3.0'),
      );
      expect(
        ChordBleConstants.formatFirmwareVersion(const [0x01, 0x02, 0x05]),
        equals('1.2.5'),
      );
    });

    test('does not confuse standard 128-bit Battery/DIS UUIDs with 9e320001', () {
      final batteryService128 = Guid('0000180f-0000-1000-8000-00805f9b34fb');
      final disService128 = Guid('0000180a-0000-1000-8000-00805f9b34fb');
      final chordService128 = Guid('9e320001-3c17-4d93-a942-a8d4594c006c');

      expect(ChordBleConstants.isChordService(batteryService128), isFalse);
      expect(ChordBleConstants.isBatteryService(batteryService128), isTrue);

      expect(ChordBleConstants.isChordService(disService128), isFalse);
      expect(ChordBleConstants.isDeviceInfoService(disService128), isTrue);

      expect(ChordBleConstants.isChordService(chordService128), isTrue);
    });

    test('DashboardState.isAudioReady reflects ASHA, LE Audio, and OS routing', () {
      final idle = DashboardState(connectionState: 'Connected');
      expect(idle.isAudioReady, isFalse);

      final ashaReady = idle.copyWith(audioTransport: ChordAudioTransport.asha);
      expect(ashaReady.isAudioReady, isTrue);

      final leAudioReady = idle.copyWith(
        audioTransport: ChordAudioTransport.leAudio,
      );
      expect(leAudioReady.isAudioReady, isTrue);

      final systemRouted = idle.copyWith(isSystemAudioRouted: true);
      expect(systemRouted.isAudioReady, isTrue);
    });
  });

  group('McubootImageInfo.parse', () {
    Uint8List buildValidMcubootBin({
      int major = 0,
      int minor = 3,
      int revision = 1,
      int buildNum = 0,
      int payloadSize = 128,
    }) {
      const headerSize = 32;
      final buffer = Uint8List(headerSize + payloadSize);
      ByteData.sublistView(buffer)
        ..setUint32(0, McubootImageInfo.mcubootMagic, Endian.little)
        ..setUint16(8, headerSize, Endian.little)
        ..setUint32(12, payloadSize, Endian.little)
        ..setUint8(20, major)
        ..setUint8(21, minor)
        ..setUint16(22, revision, Endian.little)
        ..setUint32(24, buildNum, Endian.little);
      return buffer;
    }

    test('refuses dfu_application.zip and PK zip archives', () {
      final zipBytes = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 1, 2, 3, 4]);
      expect(
        () => McubootImageInfo.parse('dfu_application.zip', zipBytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('parses valid signed MCUboot .bin header', () {
      final bin = buildValidMcubootBin(minor: 4, revision: 2);
      final info = McubootImageInfo.parse('app_update.signed.bin', bin);
      expect(info.version, equals('0.4.2'));
      expect(info.headerSize, equals(32));
      expect(info.imageSize, equals(128));
      expect(info.sha256Bytes.length, equals(32));
      expect(info.validateHardwareCompatibility('nrf5340dk'), isNull);
    });

    test('detects net core or mismatched board in filename', () {
      final bin = buildValidMcubootBin();
      final netCoreInfo = McubootImageInfo.parse('net_core_signed.bin', bin);
      expect(
        netCoreInfo.validateHardwareCompatibility('nrf5340dk'),
        isNotNull,
      );
    });
  });

  group('SmpCbor', () {
    test('round-trips definite CBOR maps', () {
      final encoded = SmpCbor.encode(<String, Object?>{
        'off': 256,
        'rc': 0,
        'confirm': false,
      });
      final decoded = SmpCbor.decode(encoded)! as Map<String, Object?>;
      expect(decoded['off'], equals(256));
      expect(decoded['rc'], equals(0));
      expect(decoded['confirm'], isFalse);
    });

    test('decodes indefinite-length CBOR maps emitted by Zephyr zcbor', () {
      // { "rc": 0, "off": 128 } with indefinite map (0xbf ... 0xff)
      final indefBytes = Uint8List.fromList([
        0xbf,
        0x62, 0x72, 0x63, // "rc"
        0x00, // 0
        0x63, 0x6f, 0x66, 0x66, // "off"
        0x18, 0x80, // 128
        0xff,
      ]);
      final decoded = SmpCbor.decode(indefBytes)! as Map<String, Object?>;
      expect(decoded['rc'], equals(0));
      expect(decoded['off'], equals(128));
    });
  });

  group('PairedDeviceRecord & PairedDevicesStorage', () {
    test('serializes and formats relative pairing time', () {
      final now = DateTime(2026, 11, 14, 19, 30);
      final record = PairedDeviceRecord(
        remoteId: 'AA:BB:CC:DD:EE:FF',
        name: 'CHORD_HA_Innov8',
        pairedAt: now.subtract(const Duration(days: 2)),
        firmwareVersion: '0.3.1',
        model: 'CHORD-1',
      );

      final roundTrip = PairedDeviceRecord.fromJson(record.toJson());
      expect(roundTrip.remoteId, equals('AA:BB:CC:DD:EE:FF'));
      expect(roundTrip.name, equals('CHORD_HA_Innov8'));
      expect(roundTrip.firmwareVersion, equals('0.3.1'));
      expect(roundTrip.model, equals('CHORD-1'));
      expect(roundTrip.formatRelativeTime(now: now), equals('Paired 2 days ago'));
    });

    test('isolates paired devices per account and supports upsert/remove', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      var currentAccount = 'user_uid_1';
      final storage = PairedDevicesStorage(
        accountIdResolver: () => currentAccount,
      );

      await storage.upsertDevice(
        PairedDeviceRecord(
          remoteId: '11:22:33:44:55:66',
          name: 'CHORD Left',
          pairedAt: DateTime(2026, 11, 12),
          firmwareVersion: '0.3.0',
        ),
      );

      final user1Devices = await storage.loadDevices();
      expect(user1Devices.length, equals(1));
      expect(user1Devices.first.name, equals('CHORD Left'));

      // Switch to a different account: should not see user_uid_1's devices
      currentAccount = 'user_uid_2';
      final user2Devices = await storage.loadDevices();
      expect(user2Devices, isEmpty);

      // Switch back to user_uid_1 and remove the device
      currentAccount = 'user_uid_1';
      final afterRemove = await storage.removeDevice('11:22:33:44:55:66');
      expect(afterRemove, isEmpty);
    });
  });

  group('CloudFirmwareManifest', () {
    test('parses Firebase Storage manifest JSON and compares versions', () {
      final manifest = CloudFirmwareManifest.fromJson(const <String, dynamic>{
        'schema': 1,
        'version': '0.3.2',
        'hardware': 'nrf5340dk',
        'board': 'nrf5340dk/nrf5340/cpuapp',
        'path':
            'firmware/images/nrf5340dk/chord_app_v0.3.2_nrf5340dk.signed.bin',
        'size': 553751,
        'sha256':
            '19f11dd2bad16c0fc58d476a22f696bc4df99982c744e289adb481881f654d01',
        'image_hash':
            '91ae99eae0fab1b6e17de65642c821e1760ff35bce141e6482dbcfb64d1ac7bc',
        'signing': 'dev',
        'notes': 'ci/cd flow test',
        'git': '43724770db34a169e0baddc373eb90764fbd2104',
        'built': '2026-11-15T11:06:18Z',
      });

      expect(manifest.version, equals('0.3.2'));
      expect(manifest.hardware, equals('nrf5340dk'));
      expect(manifest.board, equals('nrf5340dk/nrf5340/cpuapp'));
      expect(
        manifest.path,
        equals(
          'firmware/images/nrf5340dk/chord_app_v0.3.2_nrf5340dk.signed.bin',
        ),
      );
      expect(manifest.size, equals(553751));
      expect(manifest.isNewerThan('0.3.0'), isTrue);
      expect(manifest.isNewerThan('0.3.2'), isFalse);
      expect(manifest.isNewerThan('0.3.10'), isFalse);
      expect(
        CloudFirmwareManifest.compareVersions('0.3.10', '0.3.2'),
        greaterThan(0),
      );
    });
  });
}
