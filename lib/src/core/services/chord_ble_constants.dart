import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Constants and Enums for CHORD Device Interface (Firmware 0.3.x).
/// Technical reference by ChipMango Limited for Innov8 Hub.
class ChordBleConstants {
  ChordBleConstants._();

  /// Advertised device name.
  static const String advertisedName = 'CHORD_HA_Innov8';

  /// Base UUID for custom service and characteristics:
  /// 9e32XXXX-434e-4ad4-9a25-88544c414b20
  static const String baseUuidPrefix = '9e32';
  static const String baseUuidSuffix = '-434e-4ad4-9a25-88544c414b20';

  static Guid customGuid(String xxxx) =>
      Guid('$baseUuidPrefix$xxxx$baseUuidSuffix');

  // --- Services ---
  /// Chord Control Service (9e320001-434e-4ad4-9a25-88544c414b20)
  static final Guid chordControlServiceUuid = customGuid('0001');

  /// Standard Battery Service (0x180F)
  static final Guid batteryServiceUuid =
      Guid('0000180f-0000-1000-8000-00805f9b34fb');

  /// Standard Device Information Service (0x180A)
  static final Guid deviceInformationServiceUuid =
      Guid('0000180a-0000-1000-8000-00805f9b34fb');

  /// SMP Service for OTA updates (mcumgr)
  static final Guid smpServiceUuid =
      Guid('8d53dc1d-1db7-4cd3-868b-8a527460aa84');

  // --- Custom Characteristics ---
  /// Volume: 1-10 (Read, Write, Notify)
  static final Guid volumeCharacteristicUuid = customGuid('0002');

  /// Charging status: 0 discharging, 1 charging, 2 complete (Read, Notify)
  static final Guid chargingStatusCharacteristicUuid = customGuid('0004');

  /// Active profile: 1 Normal, 2 Noisy, 3 Music (Read, Write, Notify)
  static final Guid activeProfileCharacteristicUuid = customGuid('0005');

  /// Connection status: 0 disconnected, 1 connected, 2 streaming audio (Read, Notify)
  static final Guid connectionStatusCharacteristicUuid = customGuid('0006');

  /// Mic mode: 0 omni, 1 directional, 2 bypass (Read, Write, Notify)
  static final Guid micModeCharacteristicUuid = customGuid('0007');

  /// OTA progress: 0-100%, 255 idle (Read, Notify)
  static final Guid otaProgressCharacteristicUuid = customGuid('0008');

  /// Device status: 0 OK, 10 battery low, 15 battery warning (Read, Notify)
  static final Guid deviceStatusCharacteristicUuid = customGuid('0009');

  /// Control Point: opcode writes and indications (Write, Indicate)
  static final Guid controlPointCharacteristicUuid = customGuid('000b');

  /// Audio transport: 0 none, 1 LE Audio, 2 ASHA (Read, Notify)
  static final Guid audioTransportCharacteristicUuid = customGuid('000c');

  /// Mute: 0 unmuted, 1 muted (Read, Write, Notify)
  static final Guid muteCharacteristicUuid = customGuid('000d');

  /// Firmware version: UTF-8 text e.g. 0.3.0 (Read)
  static final Guid firmwareVersionCharacteristicUuid = customGuid('000e');

  /// Earpiece (DSP) state: 0 off, 1 booting, 2 ready, 3 recovering, 4 failed (Read, Notify)
  static final Guid earpieceStateCharacteristicUuid = customGuid('000f');

  // --- Standard Characteristics ---
  /// Battery Level: 0-100% (Read, Notify)
  static final Guid batteryLevelCharacteristicUuid =
      Guid('00002a19-0000-1000-8000-00805f9b34fb');

  /// Manufacturer Name String (Read)
  static final Guid manufacturerNameCharacteristicUuid =
      Guid('00002a29-0000-1000-8000-00805f9b34fb');

  /// Model Number String (Read)
  static final Guid modelNumberCharacteristicUuid =
      Guid('00002a24-0000-1000-8000-00805f9b34fb');

  /// SMP Characteristic (Write Without Response, Notify)
  static final Guid smpCharacteristicUuid =
      Guid('da2e7828-fbce-4e01-ae9e-261174997c48');

  // Audio services that must NEVER be written to by the mobile app:
  static const int ashaServiceShortUuid = 0xFDF0;
  static const int leAudioPacsShortUuid = 0x1850;
  static const int leAudioAscsShortUuid = 0x184E;
  static const int leAudioCasShortUuid = 0x1853;
  static const int leAudioHasShortUuid = 0x1854;
  static const int leAudioVcsShortUuid = 0x1844;
}

/// Control Point Opcode Commands (written to 000b)
class ChordOpcode {
  ChordOpcode._();

  /// Sync: Replies OK, re-sends every value (Live)
  static const int sync = 0x01;

  /// Factory reset: Erases all bonds and settings, reboots (Not yet run)
  static const int factoryReset = 0x02;

  /// Open pairing mode (Planned)
  static const int openPairingMode = 0x03;

  /// DSP bypass (Planned)
  static const int dspBypass = 0x04;

  /// Reload DSP (Planned)
  static const int reloadDsp = 0x05;

  /// Power off (Live, needs PMIC)
  static const int powerOff = 0x08;

  /// Reboot: Replies OK, reboots 0.5s later; link drops (Live)
  static const int reboot = 0x09;

  /// Forget all phones: Deletes every bond, ends connection (Not yet run)
  static const int forgetAllPhones = 0x0a;
}

/// Control Point Indication Status Response
enum ChordControlStatus {
  ok(0x00, 'Accepted'),
  unknownOp(0x01, 'Opcode not recognised'),
  invalidParam(0x02, 'Invalid parameter'),
  notSupported(0x03, 'Hardware or firmware cannot do this'),
  notAllowed(0x04, 'Not in current state'),
  unknown(-1, 'Unknown response');

  const ChordControlStatus(this.value, this.description);
  final int value;
  final String description;

  static ChordControlStatus fromValue(int val) {
    return ChordControlStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ChordControlStatus.unknown,
    );
  }
}

/// Microphone Modes (Characteristic 0007)
enum ChordMicMode {
  omni(0, 'Omnidirectional'),
  directional(1, 'Directional'),
  bypass(2, 'Bypass');

  const ChordMicMode(this.value, this.label);
  final int value;
  final String label;

  static ChordMicMode fromValue(int val) {
    return ChordMicMode.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ChordMicMode.omni,
    );
  }
}

/// Active Hearing Profiles (Characteristic 0005)
enum ChordProfile {
  normal(1, 'Normal'),
  noisy(2, 'Noisy'),
  music(3, 'Music');

  const ChordProfile(this.value, this.label);
  final int value;
  final String label;

  static ChordProfile fromValue(int val) {
    return ChordProfile.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ChordProfile.normal,
    );
  }
}

/// Charging Status (Characteristic 0004)
enum ChordChargingStatus {
  discharging(0, 'Discharging'),
  charging(1, 'Charging'),
  complete(2, 'Fully Charged');

  const ChordChargingStatus(this.value, this.label);
  final int value;
  final String label;

  static ChordChargingStatus fromValue(int val) {
    return ChordChargingStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ChordChargingStatus.discharging,
    );
  }
}

/// Device Telemetry Connection Status (Characteristic 0006)
enum ChordConnectionTelemetry {
  disconnected(0, 'Disconnected'),
  connected(1, 'Connected'),
  streamingAudio(2, 'Streaming Audio');

  const ChordConnectionTelemetry(this.value, this.label);
  final int value;
  final String label;

  static ChordConnectionTelemetry fromValue(int val) {
    return ChordConnectionTelemetry.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ChordConnectionTelemetry.disconnected,
    );
  }
}

/// Audio Transport (Characteristic 000c)
enum ChordAudioTransport {
  none(0, 'None'),
  leAudio(1, 'LE Audio'),
  asha(2, 'ASHA');

  const ChordAudioTransport(this.value, this.label);
  final int value;
  final String label;

  static ChordAudioTransport fromValue(int val) {
    return ChordAudioTransport.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ChordAudioTransport.none,
    );
  }
}

/// Earpiece DSP State (Characteristic 000f)
enum ChordEarpieceState {
  off(0, 'Off'),
  booting(1, 'Booting'),
  ready(2, 'Ready'),
  recovering(3, 'Recovering'),
  failed(4, 'Failed / Unplugged');

  const ChordEarpieceState(this.value, this.label);
  final int value;
  final String label;

  static ChordEarpieceState fromValue(int val) {
    return ChordEarpieceState.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ChordEarpieceState.off,
    );
  }
}

/// Device Status (Characteristic 0009)
enum ChordDeviceStatus {
  ok(0, 'OK'),
  batteryLow(10, 'Battery Low'),
  batteryWarning(15, 'Battery Warning');

  const ChordDeviceStatus(this.value, this.label);
  final int value;
  final String label;

  static ChordDeviceStatus fromValue(int val) {
    return ChordDeviceStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ChordDeviceStatus.ok,
    );
  }
}
