import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cord_hearing/src/core/services/bluetooth_device_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the developer-only "Install from file" OTA mode is unlocked.
/// Enabled automatically in [kDebugMode], or unlocked at runtime via the
/// 5-tap gesture on the Firmware Version row in Device Diagnostics.
final StateProvider<bool> developerOtaUnlockedProvider = StateProvider<bool>(
  (ref) => kDebugMode,
);

/// Parsed metadata from a 32-byte MCUboot image header (`struct image_header`).
class McubootImageInfo {
  const McubootImageInfo({
    required this.fileName,
    required this.bytes,
    required this.headerSize,
    required this.imageSize,
    required this.major,
    required this.minor,
    required this.revision,
    required this.buildNumber,
    required this.sha256Bytes,
    required this.sha256Hex,
  });

  /// Validates a picked file and parses its 32-byte MCUboot header.
  /// Throws a [FormatException] with a user-facing explanation if invalid.
  factory McubootImageInfo.parse(String fileName, Uint8List bytes) {
    final trimmedName = fileName.trim();
    final lowerName = trimmedName.toLowerCase();

    // 1. Refuse .zip archives (e.g. dfu_application.zip) or PK zip headers
    final hasZipMagic = bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
    if (lowerName.endsWith('.zip') || hasZipMagic) {
      throw FormatException(
        'Cannot upload "$trimmedName" because it is a ZIP archive. '
        'Never send dfu_application.zip directly — please unpack it first '
        'and select the signed application binary (.bin for image 0).',
      );
    }

    // 2. Refuse non-.bin extensions
    if (!lowerName.endsWith('.bin')) {
      throw FormatException(
        'Unsupported file "$trimmedName". Only a signed MCUboot .bin file '
        'for image 0 (the application core) is accepted.',
      );
    }

    // 3. Require at least the 32-byte MCUboot header
    if (bytes.length < 32) {
      throw FormatException(
        'File "$trimmedName" is too small (${bytes.length} bytes) to contain '
        'a 32-byte MCUboot header.',
      );
    }

    final bd = ByteData.sublistView(bytes);
    final magic = bd.getUint32(0, Endian.little);
    if (magic != mcubootMagic) {
      final hexMagic = '0x${magic.toRadixString(16).padLeft(8, '0')}';
      throw FormatException(
        'Invalid MCUboot header in "$trimmedName" (magic $hexMagic, '
        'expected 0x96f3b83d). Select a signed MCUboot .bin image for image 0.',
      );
    }

    final headerSize = bd.getUint16(8, Endian.little);
    final imageSize = bd.getUint32(12, Endian.little);
    final major = bd.getUint8(20);
    final minor = bd.getUint8(21);
    final revision = bd.getUint16(22, Endian.little);
    final buildNumber = bd.getUint32(24, Endian.little);

    if (imageSize == 0 || headerSize + imageSize > bytes.length) {
      throw FormatException(
        'Corrupted MCUboot image "$trimmedName": header declares '
        '${headerSize + imageSize} bytes, but file is ${bytes.length} bytes.',
      );
    }

    final digest = sha256.convert(bytes);
    final sha256Bytes = Uint8List.fromList(digest.bytes);

    return McubootImageInfo(
      fileName: trimmedName,
      bytes: bytes,
      headerSize: headerSize,
      imageSize: imageSize,
      major: major,
      minor: minor,
      revision: revision,
      buildNumber: buildNumber,
      sha256Bytes: sha256Bytes,
      sha256Hex: digest.toString(),
    );
  }

  /// MCUboot magic number `0x96f3b83d` (little-endian: `3d b8 f3 96`).
  static const int mcubootMagic = 0x96f3b83d;

  final String fileName;
  final Uint8List bytes;
  final int headerSize;
  final int imageSize;
  final int major;
  final int minor;
  final int revision;
  final int buildNumber;
  final Uint8List sha256Bytes;
  final String sha256Hex;

  /// Version formatted as `major.minor.revision` (matching `9e32000e` `v0.3.0`).
  String get version => '$major.$minor.$revision';

  /// Version including build number if non-zero.
  String get fullVersion =>
      buildNumber > 0 ? '$major.$minor.$revision+$buildNumber' : version;

  /// Checks whether this image filename conflicts with the connected device's
  /// Hardware Revision (`0x2A27`, e.g. `nrf5340dk`).
  String? validateHardwareCompatibility(String deviceHardwareRevision) {
    final hw = deviceHardwareRevision.trim().toLowerCase();
    if (hw.isEmpty) return null;
    final lowerName = fileName.toLowerCase();

    // Flag if the filename explicitly targets another nRF chip or net core
    if (lowerName.contains('net_core') ||
        lowerName.contains('cpunet') ||
        lowerName.contains('network_core')) {
      return 'Refused: "$fileName" targets the network core. Only a signed '
          '.bin for image 0 (the application core) is supported.';
    }
    if (hw.contains('nrf5340') &&
        (lowerName.contains('nrf52') || lowerName.contains('nrf91'))) {
      return 'Hardware mismatch: Image "$fileName" does not match connected '
          'Hardware Revision "$deviceHardwareRevision" (0x2A27).';
    }
    return null;
  }
}

enum OtaPhase {
  idle,
  readyToUpload,
  uploading,
  markingTestOnly,
  resetting,
  swappingAndRebooting,
  reconnecting,
  succeeded,
  rolledBack,
  failed,
}

class OtaState {
  const OtaState({
    this.phase = OtaPhase.idle,
    this.selectedImage,
    this.runningVersionBefore = '',
    this.runningVersionAfter = '',
    this.hardwareRevision = '',
    this.uploadProgress = 0,
    this.bytesSent = 0,
    this.totalBytes = 0,
    this.swapSecondsElapsed = 0,
    this.statusMessage = '',
    this.errorMessage,
  });

  final OtaPhase phase;
  final McubootImageInfo? selectedImage;
  final String runningVersionBefore;
  final String runningVersionAfter;
  final String hardwareRevision;
  final int uploadProgress;
  final int bytesSent;
  final int totalBytes;
  final int swapSecondsElapsed;
  final String statusMessage;
  final String? errorMessage;

  bool get isBusy =>
      phase == OtaPhase.uploading ||
      phase == OtaPhase.markingTestOnly ||
      phase == OtaPhase.resetting ||
      phase == OtaPhase.swappingAndRebooting ||
      phase == OtaPhase.reconnecting;

  OtaState copyWith({
    OtaPhase? phase,
    McubootImageInfo? selectedImage,
    bool clearSelectedImage = false,
    String? runningVersionBefore,
    String? runningVersionAfter,
    String? hardwareRevision,
    int? uploadProgress,
    int? bytesSent,
    int? totalBytes,
    int? swapSecondsElapsed,
    String? statusMessage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OtaState(
      phase: phase ?? this.phase,
      selectedImage: clearSelectedImage
          ? null
          : (selectedImage ?? this.selectedImage),
      runningVersionBefore: runningVersionBefore ?? this.runningVersionBefore,
      runningVersionAfter: runningVersionAfter ?? this.runningVersionAfter,
      hardwareRevision: hardwareRevision ?? this.hardwareRevision,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      bytesSent: bytesSent ?? this.bytesSent,
      totalBytes: totalBytes ?? this.totalBytes,
      swapSecondsElapsed: swapSecondsElapsed ?? this.swapSecondsElapsed,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Minimal CBOR encoder/decoder tailored for Zephyr / nRF Connect SDK `mcumgr` SMP.
class SmpCbor {
  /// Encodes a Dart value (`Map<String, Object?>`, `List`, `int`, `String`,
  /// `Uint8List`, `bool`) into definite-length CBOR bytes.
  static Uint8List encode(Object? value) {
    final builder = BytesBuilder(copy: false);
    _writeValue(builder, value);
    return builder.toBytes();
  }

  static void _writeValue(BytesBuilder out, Object? value) {
    if (value == null) {
      out.addByte(0xf6);
    } else if (value is bool) {
      out.addByte(value ? 0xf5 : 0xf4);
    } else if (value is int) {
      if (value >= 0) {
        _writeTypeAndLength(out, 0, value);
      } else {
        _writeTypeAndLength(out, 1, -1 - value);
      }
    } else if (value is Uint8List) {
      _writeTypeAndLength(out, 2, value.length);
      out.add(value);
    } else if (value is List<int>) {
      _writeTypeAndLength(out, 2, value.length);
      out.add(value);
    } else if (value is String) {
      final utf8Bytes = utf8.encode(value);
      _writeTypeAndLength(out, 3, utf8Bytes.length);
      out.add(utf8Bytes);
    } else if (value is List) {
      _writeTypeAndLength(out, 4, value.length);
      for (final item in value) {
        _writeValue(out, item);
      }
    } else if (value is Map) {
      _writeTypeAndLength(out, 5, value.length);
      for (final entry in value.entries) {
        _writeValue(out, entry.key);
        _writeValue(out, entry.value);
      }
    } else {
      throw ArgumentError('Unsupported CBOR type: ${value.runtimeType}');
    }
  }

  static void _writeTypeAndLength(BytesBuilder out, int majorType, int length) {
    final prefix = majorType << 5;
    if (length < 24) {
      out.addByte(prefix | length);
    } else if (length <= 0xFF) {
      out
        ..addByte(prefix | 24)
        ..addByte(length);
    } else if (length <= 0xFFFF) {
      out
        ..addByte(prefix | 25)
        ..addByte((length >> 8) & 0xFF)
        ..addByte(length & 0xFF);
    } else if (length <= 0xFFFFFFFF) {
      out
        ..addByte(prefix | 26)
        ..addByte((length >> 24) & 0xFF)
        ..addByte((length >> 16) & 0xFF)
        ..addByte((length >> 8) & 0xFF)
        ..addByte(length & 0xFF);
    } else {
      out.addByte(prefix | 27);
      for (var shift = 56; shift >= 0; shift -= 8) {
        out.addByte((length >> shift) & 0xFF);
      }
    }
  }

  /// Decodes a CBOR byte buffer (supporting both definite and indefinite
  /// lengths used by Zephyr `zcbor`/`tinycbor`) into a Dart map/object.
  static Object? decode(Uint8List bytes) {
    if (bytes.isEmpty) return <String, Object?>{};
    final reader = _CborReader(bytes);
    return reader.readValue();
  }
}

class _CborReader {
  _CborReader(this.bytes);

  final Uint8List bytes;
  int offset = 0;

  Object? readValue() {
    if (offset >= bytes.length) return null;
    final initial = bytes[offset++];
    final majorType = initial >> 5;
    final additional = initial & 0x1f;

    switch (majorType) {
      case 0: // Unsigned int
        return _readLength(additional);
      case 1: // Negative int
        return -1 - _readLength(additional);
      case 2: // Byte string
        if (additional == 31) {
          final builder = BytesBuilder(copy: false);
          while (offset < bytes.length && bytes[offset] != 0xff) {
            final chunk = readValue();
            if (chunk is Uint8List) builder.add(chunk);
          }
          if (offset < bytes.length && bytes[offset] == 0xff) offset++;
          return builder.toBytes();
        }
        final len = _readLength(additional);
        final end = math.min(offset + len, bytes.length);
        final slice = Uint8List.sublistView(bytes, offset, end);
        offset = end;
        return slice;
      case 3: // Text string
        if (additional == 31) {
          final sb = StringBuffer();
          while (offset < bytes.length && bytes[offset] != 0xff) {
            final chunk = readValue();
            if (chunk is String) sb.write(chunk);
          }
          if (offset < bytes.length && bytes[offset] == 0xff) offset++;
          return sb.toString();
        }
        final len = _readLength(additional);
        final end = math.min(offset + len, bytes.length);
        final str = utf8.decode(
          Uint8List.sublistView(bytes, offset, end),
          allowMalformed: true,
        );
        offset = end;
        return str;
      case 4: // Array
        final list = <Object?>[];
        if (additional == 31) {
          while (offset < bytes.length && bytes[offset] != 0xff) {
            list.add(readValue());
          }
          if (offset < bytes.length && bytes[offset] == 0xff) offset++;
        } else {
          final len = _readLength(additional);
          for (var i = 0; i < len && offset < bytes.length; i++) {
            list.add(readValue());
          }
        }
        return list;
      case 5: // Map
        final map = <String, Object?>{};
        if (additional == 31) {
          while (offset < bytes.length && bytes[offset] != 0xff) {
            final key = readValue()?.toString() ?? '';
            final val = readValue();
            map[key] = val;
          }
          if (offset < bytes.length && bytes[offset] == 0xff) offset++;
        } else {
          final len = _readLength(additional);
          for (var i = 0; i < len && offset < bytes.length; i++) {
            final key = readValue()?.toString() ?? '';
            final val = readValue();
            map[key] = val;
          }
        }
        return map;
      case 6: // Semantic tag
        _readLength(additional);
        return readValue();
      case 7: // Simple / float
        if (additional == 20) return false;
        if (additional == 21) return true;
        if (additional == 22 || additional == 23) return null;
        if (additional == 24) {
          offset++;
          return null;
        }
        if (additional == 25) {
          offset += 2;
          return null;
        }
        if (additional == 26) {
          offset += 4;
          return null;
        }
        if (additional == 27) {
          offset += 8;
          return null;
        }
        return null;
      default:
        return null;
    }
  }

  int _readLength(int additional) {
    if (additional < 24) return additional;
    if (additional == 24) {
      return bytes[offset++];
    }
    if (additional == 25) {
      final v = (bytes[offset] << 8) | bytes[offset + 1];
      offset += 2;
      return v;
    }
    if (additional == 26) {
      final v = (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      offset += 4;
      return v;
    }
    if (additional == 27) {
      var v = 0;
      for (var i = 0; i < 8; i++) {
        v = (v << 8) | bytes[offset + i];
      }
      offset += 8;
      return v;
    }
    return 0;
  }
}

/// Controller managing the Section 8 Local-File SMP (`mcumgr`) Firmware Update.
class ChordOtaController extends AutoDisposeNotifier<OtaState> {
  static const MethodChannel _filePickerChannel = MethodChannel(
    'com.cordhearingaid.app/ota_file_picker',
  );

  int _seq = 0;
  bool _cancelled = false;

  @override
  OtaState build() {
    final repo = ref.read(deviceRepositoryProvider);
    ref.onDispose(() {
      _cancelled = true;
    });
    return OtaState(
      runningVersionBefore: repo.currentFirmwareVersion,
      hardwareRevision: repo.currentHardwareRevision,
    );
  }

  /// Opens the native system document picker, validates that the file is a
  /// signed `.bin` for image 0 (rejecting `.zip` / `dfu_application.zip`),
  /// parses the 32-byte MCUboot header, and compares with Hardware Revision.
  Future<void> pickLocalFirmwareFile() async {
    final repo = ref.read(deviceRepositoryProvider);
    final runningVer = repo.currentFirmwareVersion;
    final hwRev = repo.currentHardwareRevision;

    try {
      final result = await _filePickerChannel
          .invokeMapMethod<String, dynamic>('pickFirmwareFile');
      if (result == null) {
        return; // User cancelled picker
      }

      final fileName = (result['name'] as String?) ?? 'firmware.bin';
      final rawBytes = result['bytes'];
      final Uint8List bytes;
      if (rawBytes is Uint8List) {
        bytes = rawBytes;
      } else if (rawBytes is List<int>) {
        bytes = Uint8List.fromList(rawBytes);
      } else {
        throw const FormatException('Unable to read bytes from selected file.');
      }

      final imageInfo = McubootImageInfo.parse(fileName, bytes);
      final hwMismatch = imageInfo.validateHardwareCompatibility(hwRev);

      if (hwMismatch != null) {
        state = state.copyWith(
          phase: OtaPhase.failed,
          clearSelectedImage: true,
          runningVersionBefore: runningVer,
          hardwareRevision: hwRev,
          errorMessage: hwMismatch,
        );
        return;
      }

      state = state.copyWith(
        phase: OtaPhase.readyToUpload,
        selectedImage: imageInfo,
        runningVersionBefore: runningVer,
        hardwareRevision: hwRev,
        uploadProgress: 0,
        bytesSent: 0,
        totalBytes: imageInfo.bytes.length,
        statusMessage:
            'Ready to upload ${imageInfo.fileName} (v${imageInfo.version})',
        clearError: true,
      );
    } on FormatException catch (e) {
      state = state.copyWith(
        phase: OtaPhase.failed,
        clearSelectedImage: true,
        runningVersionBefore: runningVer,
        hardwareRevision: hwRev,
        errorMessage: e.message,
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        phase: OtaPhase.failed,
        clearSelectedImage: true,
        runningVersionBefore: runningVer,
        hardwareRevision: hwRev,
        errorMessage: e.message ?? 'Failed to open file picker.',
      );
    } catch (e) {
      state = state.copyWith(
        phase: OtaPhase.failed,
        clearSelectedImage: true,
        runningVersionBefore: runningVer,
        hardwareRevision: hwRev,
        errorMessage: e.toString(),
      );
    }
  }

  /// Executes the full SMP (`mcumgr`) Test-Only OTA workflow:
  /// 1. Pre-conditions check (battery >= 30%, not streaming, SMP characteristic ready)
  /// 2. Image Upload (`Group 1, ID 1`) with live progress
  /// 3. Mark Slot 1 for Test-Only (`Group 1, ID 0`, `confirm: false`)
  /// 4. Reset device (`Group 0, ID 5`)
  /// 5. Wait up to 90s for MCUboot image swap (45–60s expected) & auto-reconnect
  /// 6. Read `9e32000e` to confirm update success vs. rollback
  Future<void> startFirmwareUpload() async {
    final image = state.selectedImage;
    if (image == null || state.isBusy) return;

    final repo = ref.read(deviceRepositoryProvider);
    _cancelled = false;

    // 1. Preconditions check
    if (!repo.isConnected) {
      state = state.copyWith(
        phase: OtaPhase.failed,
        errorMessage: 'CHORD device is disconnected. Please connect first.',
      );
      return;
    }
    if (repo.currentBatteryLevel > 0 && repo.currentBatteryLevel < 30) {
      state = state.copyWith(
        phase: OtaPhase.failed,
        errorMessage:
            'Battery is at ${repo.currentBatteryLevel}%. At least 30% is required for OTA update.',
      );
      return;
    }
    if (repo.currentConnectionTelemetry ==
        ChordConnectionTelemetry.streamingAudio) {
      state = state.copyWith(
        phase: OtaPhase.failed,
        errorMessage:
            'Audio is currently streaming. Please pause audio playback before updating firmware.',
      );
      return;
    }

    final smpChar = repo.smpCharacteristic;
    if (smpChar == null) {
      state = state.copyWith(
        phase: OtaPhase.failed,
        errorMessage:
            'SMP (mcumgr) characteristic (da2e7828-...) was not found on this device.',
      );
      return;
    }

    final preUpdateVersion = repo.currentFirmwareVersion;
    state = state.copyWith(
      phase: OtaPhase.uploading,
      runningVersionBefore: preUpdateVersion,
      hardwareRevision: repo.currentHardwareRevision,
      uploadProgress: 0,
      bytesSent: 0,
      totalBytes: image.bytes.length,
      statusMessage: 'Preparing SMP channel...',
      clearError: true,
    );

    StreamSubscription<int>? chordOtaProgressSub;

    try {
      // Ensure SMP notifications are enabled
      await smpChar.setNotifyValue(true);

      // Listen for optional firmware-reported progress on 9e320008
      chordOtaProgressSub = repo.otaProgress.listen((pct) {
        if (state.phase == OtaPhase.uploading && pct > state.uploadProgress) {
          state = state.copyWith(uploadProgress: pct.clamp(0, 100));
        }
      });

      final device = repo.connectedDevice;
      final mtu = device?.mtuNow ?? 247;
      // Leave room for 3-byte ATT header + 8-byte SMP header + CBOR framing
      final maxPacketSize = math.max(128, math.min(mtu - 3, 490));

      var offset = 0;
      final totalLen = image.bytes.length;

      while (offset < totalLen) {
        if (_cancelled) {
          throw Exception('Firmware update cancelled.');
        }

        // First packet includes image: 0, len, and 32-byte sha256
        final overhead = offset == 0 ? 78 : 24;
        final maxChunk = math.max(32, maxPacketSize - overhead);
        final chunkEnd = math.min(offset + maxChunk, totalLen);
        final chunk = Uint8List.sublistView(image.bytes, offset, chunkEnd);

        final payload = <String, Object?>{
          if (offset == 0) 'image': 0,
          'data': chunk,
          if (offset == 0) 'len': totalLen,
          'off': offset,
          if (offset == 0) 'sha': image.sha256Bytes,
        };

        final response = await _sendSmpCommand(
          smpChar,
          op: 2, // Write Request
          group: 1, // MGMT_GROUP_ID_IMAGE
          id: 1, // IMAGE_NMGR_ID_UPLOAD
          payload: payload,
          maxWriteSize: math.max(20, mtu - 3),
          timeout: const Duration(seconds: 12),
        );

        final rc = response['rc'];
        if (rc is int && rc != 0) {
          throw Exception(
            'SMP upload rejected by device (mcumgr rc=$rc at offset $offset).',
          );
        }

        final nextOff = response['off'];
        if (nextOff is int && nextOff > offset) {
          offset = nextOff;
        } else {
          offset = chunkEnd;
        }

        final pct = ((offset * 100) / totalLen).round().clamp(0, 100);
        state = state.copyWith(
          phase: OtaPhase.uploading,
          uploadProgress: pct,
          bytesSent: offset,
          totalBytes: totalLen,
          statusMessage:
              'Uploading firmware over BLE SMP... $pct% (${(offset / 1024).toStringAsFixed(1)} / ${(totalLen / 1024).toStringAsFixed(1)} KB)',
        );
      }

      // 3. Mark uploaded image in Slot 1 for Test-Only (confirm: false)
      state = state.copyWith(
        phase: OtaPhase.markingTestOnly,
        uploadProgress: 100,
        statusMessage: 'Setting image to Test-Only mode (never confirm from app)...',
      );

      final stateResponse = await _sendSmpCommand(
        smpChar,
        op: 0, // Read Request
        group: 1, // MGMT_GROUP_ID_IMAGE
        id: 0, // IMAGE_NMGR_ID_STATE
        payload: const <String, Object?>{},
        maxWriteSize: math.max(20, mtu - 3),
        timeout: const Duration(seconds: 8),
      );

      final slot1Hash = _extractSlot1Hash(stateResponse);
      final testPayload = <String, Object?>{
        'confirm': false, // Test-only: firmware confirms itself on boot
        if (slot1Hash != null) 'hash': slot1Hash,
      };

      final testResponse = await _sendSmpCommand(
        smpChar,
        op: 2, // Write Request
        group: 1, // MGMT_GROUP_ID_IMAGE
        id: 0, // IMAGE_NMGR_ID_STATE
        payload: testPayload,
        maxWriteSize: math.max(20, mtu - 3),
        timeout: const Duration(seconds: 8),
      );

      final testRc = testResponse['rc'];
      if (testRc is int && testRc != 0) {
        throw Exception('Failed to mark image for test swap (rc=$testRc).');
      }

      // 4. Reset device to trigger MCUboot swap
      state = state.copyWith(
        phase: OtaPhase.resetting,
        statusMessage: 'Rebooting CHORD to start MCUboot image swap...',
      );

      try {
        await _sendSmpCommand(
          smpChar,
          op: 2, // Write Request
          group: 0, // MGMT_GROUP_ID_OS
          id: 5, // OS_NMGR_ID_RESET
          payload: const <String, Object?>{},
          maxWriteSize: math.max(20, mtu - 3),
          timeout: const Duration(seconds: 5),
        );
      } catch (_) {
        // Fallback to CHORD Control Point Reboot (Opcode 0x09)
        await repo.reboot();
      }

      await chordOtaProgressSub.cancel();
      chordOtaProgressSub = null;

      // 5. Wait up to 90 seconds for MCUboot swap (45–60s expected) & reconnect
      await _waitForSwapAndReconnect(
        preUpdateVersion: preUpdateVersion,
        targetImageVersion: image.version,
      );
    } catch (e) {
      state = state.copyWith(
        phase: OtaPhase.failed,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      await chordOtaProgressSub?.cancel();
    }
  }

  Uint8List? _extractSlot1Hash(Map<String, Object?> stateResponse) {
    final images = stateResponse['images'];
    if (images is List) {
      for (final item in images) {
        if (item is Map) {
          final slot = item['slot'];
          final hash = item['hash'];
          if (slot == 1 && hash is Uint8List) {
            return hash;
          }
        }
      }
      // Fallback: if slot key is omitted, second entry is slot 1
      if (images.length > 1 && images[1] is Map) {
        final hash = (images[1] as Map)['hash'];
        if (hash is Uint8List) return hash;
      }
    }
    return null;
  }

  Future<Map<String, Object?>> _sendSmpCommand(
    BluetoothCharacteristic smpChar, {
    required int op,
    required int group,
    required int id,
    required Map<String, Object?> payload,
    required int maxWriteSize,
    required Duration timeout,
  }) async {
    final cborBytes = SmpCbor.encode(payload);
    final seq = _seq;
    _seq = (_seq + 1) & 0xFF;

    final packet = Uint8List(8 + cborBytes.length);
    packet[0] = op & 0xFF;
    packet[1] = 0; // flags
    packet[2] = (cborBytes.length >> 8) & 0xFF;
    packet[3] = cborBytes.length & 0xFF;
    packet[4] = (group >> 8) & 0xFF;
    packet[5] = group & 0xFF;
    packet[6] = seq;
    packet[7] = id & 0xFF;
    packet.setRange(8, packet.length, cborBytes);

    final completer = Completer<Map<String, Object?>>();
    final rxBuffer = BytesBuilder(copy: false);
    int? expectedPayloadLen;

    final sub = smpChar.onValueReceived.listen((chunk) {
      if (chunk.isEmpty || completer.isCompleted) return;
      rxBuffer.add(chunk);
      final current = rxBuffer.toBytes();
      if (current.length >= 8) {
        expectedPayloadLen ??= (current[2] << 8) | current[3];
        if (current.length >= 8 + expectedPayloadLen!) {
          final cborSlice = Uint8List.sublistView(
            current,
            8,
            8 + expectedPayloadLen!,
          );
          final decoded = SmpCbor.decode(cborSlice);
          if (decoded is Map<String, Object?>) {
            completer.complete(decoded);
          } else if (decoded is Map) {
            completer.complete(
              decoded.map((k, v) => MapEntry(k.toString(), v)),
            );
          } else {
            completer.complete(<String, Object?>{});
          }
        }
      }
    });

    try {
      // Send packet (fragmenting across maxWriteSize if needed)
      final canWriteWithoutResponse =
          smpChar.properties.writeWithoutResponse;
      for (var i = 0; i < packet.length; i += maxWriteSize) {
        final end = math.min(i + maxWriteSize, packet.length);
        final slice = Uint8List.sublistView(packet, i, end);
        await smpChar.write(
          slice,
          withoutResponse: canWriteWithoutResponse,
        );
      }

      return await completer.future.timeout(timeout);
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _waitForSwapAndReconnect({
    required String preUpdateVersion,
    required String targetImageVersion,
  }) async {
    final repo = ref.read(deviceRepositoryProvider);
    final targetDevice = repo.connectedDevice ?? repo.lastConnectedDevice;

    const maxWaitSeconds = 90;
    for (var elapsed = 1; elapsed <= maxWaitSeconds; elapsed++) {
      if (_cancelled) return;

      state = state.copyWith(
        phase: elapsed < 12
            ? OtaPhase.swappingAndRebooting
            : OtaPhase.reconnecting,
        swapSecondsElapsed: elapsed,
        statusMessage: elapsed < 12
            ? 'MCUboot is swapping firmware images (${elapsed}s / ${maxWaitSeconds}s)...'
            : 'Waiting for CHORD to finish swap & reconnecting (${elapsed}s / ${maxWaitSeconds}s — 45–60s expected)...',
      );

      await Future<void>.delayed(const Duration(seconds: 1));

      // Start attempting reconnection after 12s (allowing reset + swap entry)
      if (elapsed >= 12 && elapsed % 5 == 0) {
        try {
          var candidate = targetDevice;
          if (candidate == null) {
            final sys = await repo.getSystemConnectedDevices();
            if (sys.isNotEmpty) candidate = sys.first;
          }
          if (candidate != null) {
            await repo.connect(candidate);
            if (repo.isConnected) {
              // Wait briefly for telemetry read of 9e32000e
              await Future<void>.delayed(const Duration(milliseconds: 600));
              final newVer = repo.currentFirmwareVersion;
              if (newVer.isNotEmpty) {
                final updatedToTarget = newVer == targetImageVersion;
                if (updatedToTarget) {
                  state = state.copyWith(
                    phase: OtaPhase.succeeded,
                    runningVersionAfter: newVer,
                    swapSecondsElapsed: elapsed,
                    statusMessage:
                        'Update succeeded! CHORD booted v$newVer and confirmed the image.',
                  );
                } else {
                  state = state.copyWith(
                    phase: OtaPhase.rolledBack,
                    runningVersionAfter: newVer,
                    swapSecondsElapsed: elapsed,
                    statusMessage:
                        'Update rolled back: CHORD booted on v$newVer (expected v$targetImageVersion).',
                  );
                }
                return;
              }
            }
          }
        } catch (_) {
          // Device still swapping in MCUboot; continue waiting up to 90s
        }
      }
    }

    state = state.copyWith(
      phase: OtaPhase.failed,
      swapSecondsElapsed: maxWaitSeconds,
      errorMessage:
          'Timed out after 90 seconds waiting for CHORD to reconnect after MCUboot swap. Please check the device and reconnect manually.',
    );
  }

  void resetState() {
    final repo = ref.read(deviceRepositoryProvider);
    state = OtaState(
      runningVersionBefore: repo.currentFirmwareVersion,
      hardwareRevision: repo.currentHardwareRevision,
    );
  }
}

final AutoDisposeNotifierProvider<ChordOtaController, OtaState>
chordOtaProvider =
    NotifierProvider.autoDispose<ChordOtaController, OtaState>(
      ChordOtaController.new,
    );
