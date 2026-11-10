import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

export 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
export 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show
        BluetoothCharacteristic,
        BluetoothConnectionState,
        BluetoothDevice,
        Guid;

// Backward compatibility typedef for existing views
typedef MicMode = ChordMicMode;

/// Provider for the BluetoothDeviceRepository.
final deviceRepositoryProvider = Provider<BluetoothDeviceRepository>((ref) {
  final service = BluetoothDeviceService();
  ref.onDispose(service.dispose);
  return service;
});

abstract class BluetoothDeviceRepository {
  /// Currently connected device
  BluetoothDevice? get connectedDevice;

  /// Last connected device (for reconnect after disconnect or OTA reboot)
  BluetoothDevice? get lastConnectedDevice;

  /// SMP characteristic for MCUboot OTA firmware uploads
  BluetoothCharacteristic? get smpCharacteristic;

  /// Whether the device is currently connected
  bool get isConnected;

  /// Current connection state
  BluetoothConnectionState get currentConnectionState;

  /// Current battery level (0-100%)
  int get currentBatteryLevel;

  /// Current telemetry connection status
  ChordConnectionTelemetry get currentConnectionTelemetry;

  /// Current device status
  ChordDeviceStatus get currentDeviceStatus;

  /// Connection state stream
  Stream<BluetoothConnectionState> get connectionState;

  /// Telemetry Streams
  Stream<int> get batteryLevel;
  Stream<int> get volume;
  Stream<bool> get isMuted;
  Stream<ChordProfile> get activeProfile;
  Stream<ChordMicMode> get micMode;
  Stream<ChordChargingStatus> get chargingStatus;
  Stream<ChordDeviceStatus> get deviceStatus;
  Stream<ChordConnectionTelemetry> get connectionTelemetry;
  Stream<ChordAudioTransport> get audioTransport;
  Stream<ChordEarpieceState> get earpieceState;
  Stream<ChordFaultCode> get faultCode;
  Stream<int> get otaProgress;
  Stream<String> get firmwareVersion;
  Stream<String> get hardwareRevision;
  Stream<String> get manufacturerName;
  Stream<String> get modelNumber;
  Stream<MapEntry<int, ChordControlStatus>> get controlResponses;
  Stream<bool> get isSystemAudioRouted;

  // Cached current values for synchronous access
  int get currentVolume;
  bool get currentIsMuted;
  ChordProfile get currentProfile;
  ChordMicMode get currentMicMode;
  ChordEarpieceState get currentEarpieceState;
  ChordFaultCode get currentFaultCode;
  ChordChargingStatus get currentChargingStatus;
  ChordAudioTransport get currentAudioTransport;
  String get currentFirmwareVersion;
  String get currentHardwareRevision;
  String get currentManufacturer;
  String get currentModel;
  bool get currentIsSystemAudioRouted;

  /// Permissions & discovery
  Future<bool> checkAndRequestPermissions();
  Future<List<BluetoothDevice>> getSystemConnectedDevices();

  /// Lifecycle
  Future<void> connect(BluetoothDevice device);
  Future<void> disconnect();

  /// OS Audio Profile & Routing (ASHA / LE Audio / A2DP / HFP)
  Future<bool> enableAudioStreaming();
  Future<void> openSystemBluetoothSettings();

  /// Controls (single-byte writes)
  Future<void> setVolume(int step);
  Future<void> setMute(bool mute);
  Future<void> setProfile(ChordProfile profile);
  Future<void> setMicMode(ChordMicMode mode);

  /// Commands (Control Point 000b)
  Future<void> sync();
  Future<void> reboot();
  Future<void> factoryReset();
  Future<void> forgetAllPhones();
  Future<void> powerOff();
  Future<void> openPairingMode();

  /// Legacy/general status request
  Future<void> requestStatus();
}

class BluetoothDeviceService implements BluetoothDeviceRepository {
  static const MethodChannel _audioChannel = MethodChannel(
    'com.cordhearingaid.app/bluetooth_audio',
  );

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? _lastConnectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  final List<StreamSubscription<dynamic>> _characteristicSubscriptions = [];

  // Controllers
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  final _batteryLevelController = StreamController<int>.broadcast();
  final _volumeController = StreamController<int>.broadcast();
  final _muteController = StreamController<bool>.broadcast();
  final _profileController = StreamController<ChordProfile>.broadcast();
  final _micModeController = StreamController<ChordMicMode>.broadcast();
  final _chargingStatusController =
      StreamController<ChordChargingStatus>.broadcast();
  final _deviceStatusController =
      StreamController<ChordDeviceStatus>.broadcast();
  final _connectionTelemetryController =
      StreamController<ChordConnectionTelemetry>.broadcast();
  final _audioTransportController =
      StreamController<ChordAudioTransport>.broadcast();
  final _earpieceStateController =
      StreamController<ChordEarpieceState>.broadcast();
  final _faultCodeController = StreamController<ChordFaultCode>.broadcast();
  final _otaProgressController = StreamController<int>.broadcast();
  final _firmwareVersionController = StreamController<String>.broadcast();
  final _hardwareRevisionController = StreamController<String>.broadcast();
  final _manufacturerController = StreamController<String>.broadcast();
  final _modelController = StreamController<String>.broadcast();
  final _controlResponseController =
      StreamController<MapEntry<int, ChordControlStatus>>.broadcast();
  final _systemAudioRoutedController = StreamController<bool>.broadcast();

  // Cached values
  BluetoothConnectionState _currentConnectionState =
      BluetoothConnectionState.disconnected;
  int _currentBatteryLevel = 0;
  ChordConnectionTelemetry _currentConnectionTelemetry =
      ChordConnectionTelemetry.disconnected;
  ChordDeviceStatus _currentDeviceStatus = ChordDeviceStatus.ok;
  int _currentVolume = 5;
  bool _currentIsMuted = false;
  ChordProfile _currentProfile = ChordProfile.normal;
  ChordMicMode _currentMicMode = ChordMicMode.omni;
  ChordEarpieceState _currentEarpieceState = ChordEarpieceState.ready;
  ChordFaultCode _currentFaultCode = ChordFaultCode.none;
  ChordChargingStatus _currentChargingStatus = ChordChargingStatus.discharging;
  ChordAudioTransport _currentAudioTransport = ChordAudioTransport.none;
  String _currentFirmwareVersion = '';
  String _currentHardwareRevision = '';
  String _currentManufacturer = '';
  String _currentModel = '';
  bool _currentIsSystemAudioRouted = false;

  // Cached characteristics for fast access and explicit post-pairing reads
  BluetoothCharacteristic? _volumeChar;
  BluetoothCharacteristic? _muteChar;
  BluetoothCharacteristic? _profileChar;
  BluetoothCharacteristic? _micModeChar;
  BluetoothCharacteristic? _chargingStatusChar;
  BluetoothCharacteristic? _deviceStatusChar;
  BluetoothCharacteristic? _connectionStatusChar;
  BluetoothCharacteristic? _audioTransportChar;
  BluetoothCharacteristic? _earpieceStateChar;
  BluetoothCharacteristic? _faultCodeChar;
  BluetoothCharacteristic? _firmwareVersionChar;
  BluetoothCharacteristic? _controlPointChar;
  BluetoothCharacteristic? _batteryChar;
  BluetoothCharacteristic? _manufacturerChar;
  BluetoothCharacteristic? _modelChar;
  BluetoothCharacteristic? _hardwareRevisionChar;
  BluetoothCharacteristic? _smpChar;

  @override
  BluetoothDevice? get connectedDevice => _connectedDevice;

  @override
  BluetoothDevice? get lastConnectedDevice => _lastConnectedDevice;

  @override
  BluetoothCharacteristic? get smpCharacteristic => _smpChar;

  @override
  bool get isConnected =>
      _connectedDevice != null &&
      _currentConnectionState == BluetoothConnectionState.connected;

  @override
  BluetoothConnectionState get currentConnectionState =>
      _currentConnectionState;

  @override
  int get currentBatteryLevel => _currentBatteryLevel;

  @override
  ChordConnectionTelemetry get currentConnectionTelemetry =>
      _currentConnectionTelemetry;

  @override
  ChordDeviceStatus get currentDeviceStatus => _currentDeviceStatus;

  @override
  Stream<BluetoothConnectionState> get connectionState =>
      _connectionStateController.stream;
  @override
  Stream<int> get batteryLevel => _batteryLevelController.stream;
  @override
  Stream<int> get volume => _volumeController.stream;
  @override
  Stream<bool> get isMuted => _muteController.stream;
  @override
  Stream<ChordProfile> get activeProfile => _profileController.stream;
  @override
  Stream<ChordMicMode> get micMode => _micModeController.stream;
  @override
  Stream<ChordChargingStatus> get chargingStatus =>
      _chargingStatusController.stream;
  @override
  Stream<ChordDeviceStatus> get deviceStatus => _deviceStatusController.stream;
  @override
  Stream<ChordConnectionTelemetry> get connectionTelemetry =>
      _connectionTelemetryController.stream;
  @override
  Stream<ChordAudioTransport> get audioTransport =>
      _audioTransportController.stream;
  @override
  Stream<ChordEarpieceState> get earpieceState =>
      _earpieceStateController.stream;
  @override
  Stream<ChordFaultCode> get faultCode => _faultCodeController.stream;
  @override
  Stream<int> get otaProgress => _otaProgressController.stream;
  @override
  Stream<String> get firmwareVersion => _firmwareVersionController.stream;
  @override
  Stream<String> get hardwareRevision => _hardwareRevisionController.stream;
  @override
  Stream<String> get manufacturerName => _manufacturerController.stream;
  @override
  Stream<String> get modelNumber => _modelController.stream;
  @override
  Stream<MapEntry<int, ChordControlStatus>> get controlResponses =>
      _controlResponseController.stream;
  @override
  Stream<bool> get isSystemAudioRouted => _systemAudioRoutedController.stream;

  @override
  int get currentVolume => _currentVolume;
  @override
  bool get currentIsMuted => _currentIsMuted;
  @override
  ChordProfile get currentProfile => _currentProfile;
  @override
  ChordMicMode get currentMicMode => _currentMicMode;
  @override
  ChordEarpieceState get currentEarpieceState => _currentEarpieceState;
  @override
  ChordFaultCode get currentFaultCode => _currentFaultCode;
  @override
  ChordChargingStatus get currentChargingStatus => _currentChargingStatus;
  @override
  ChordAudioTransport get currentAudioTransport => _currentAudioTransport;
  @override
  String get currentFirmwareVersion => _currentFirmwareVersion;
  @override
  String get currentHardwareRevision => _currentHardwareRevision;
  @override
  String get currentManufacturer => _currentManufacturer;
  @override
  String get currentModel => _currentModel;
  @override
  bool get currentIsSystemAudioRouted => _currentIsSystemAudioRouted;

  @override
  Future<bool> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      // Android 12+ (API 31+) needs BLUETOOTH_SCAN + BLUETOOTH_CONNECT.
      // Android < 12 needs location for BLE scanning.
      // We request both to cover all Android versions.
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse, // Replaces deprecated Permission.location
      ].request();

      // Accept both 'granted' and 'limited' as valid
      return statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );
    }
    // On iOS, CoreBluetooth requests permissions automatically when scanning.
    return true;
  }

  @override
  Future<List<BluetoothDevice>> getSystemConnectedDevices() async {
    final result = <String, BluetoothDevice>{};
    try {
      final devices = await FlutterBluePlus.systemDevices([
        ChordBleConstants.chordControlServiceUuid,
      ]);
      for (final d in devices) {
        result[d.remoteId.str] = d;
      }
    } catch (e) {
      debugPrint('Error retrieving system connected devices: $e');
    }
    if (Platform.isAndroid) {
      var audioConnectedIds = <String>{};
      try {
        final rawAddresses = await _audioChannel.invokeListMethod<String>(
          'getAudioConnectedDevices',
        );
        if (rawAddresses != null) {
          audioConnectedIds = rawAddresses
              .map((a) => a.toUpperCase())
              .toSet();
        }
      } catch (e) {
        debugPrint('Error retrieving audio connected devices: $e');
      }

      try {
        final bonded = await FlutterBluePlus.bondedDevices;
        for (final d in bonded) {
          final upperName = d.platformName.toUpperCase();
          final upperId = d.remoteId.str.toUpperCase();
          if (upperName.contains('CHORD') ||
              upperName.contains('COCHLEAR') ||
              audioConnectedIds.contains(upperId)) {
            result[d.remoteId.str] = d;
          }
        }
      } catch (e) {
        debugPrint('Error retrieving bonded devices: $e');
      }
    }
    return result.values.toList();
  }

  @override
  Future<void> connect(BluetoothDevice device) async {
    // 1. Stop scanning before connecting to avoid Android GATT Error 133
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    // Only disconnect if a different device was previously connected.
    // Never disconnect the target device before connecting: on Android, the OS
    // already holds the link to a bonded hearing aid (LE Audio / ASHA), so
    // device.connect() opens our GATT client on that existing link.
    if (_connectedDevice != null &&
        _connectedDevice!.remoteId != device.remoteId) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
    }

    _clearCharacteristicCache();

    // Listen to device connection state changes (Android onConnectionStateChange)
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen((state) {
      _currentConnectionState = state;
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.connected) {
        _connectedDevice = device;
        _lastConnectedDevice = device;
      } else if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        _currentConnectionTelemetry = ChordConnectionTelemetry.disconnected;
        _currentIsSystemAudioRouted = false;
        _systemAudioRoutedController.add(false);
        _clearCharacteristicCache();
      }
    });

    // Connect GATT client on the device link
    await device.connect(mtu: null);
    _connectedDevice = device;
    _lastConnectedDevice = device;
    _currentConnectionState = BluetoothConnectionState.connected;
    _connectionStateController.add(BluetoothConnectionState.connected);

    // On Android, ensure OS-level bonding (createBond) and activate the
    // system Hearing Aid (ASHA) / LE Audio profiles so music and calls route
    // through the hearing aid even when connecting via the app.
    if (Platform.isAndroid) {
      await _ensureAndroidBondAndAudio(device);
    }

    // Request ATT MTU up to 498 as specified in Chord tech reference
    try {
      await device.requestMtu(498);
    } catch (e) {
      debugPrint('MTU request error: $e');
    }

    // Discover services and subscribe to notifications/indications
    final services = await device.discoverServices();
    await _setupCharacteristicsAndSubscriptions(services);

    // Initial sync: Write 0x01 to Control Point (000b) AND explicitly read
    // Battery Level (0x2A19), Firmware Version (000e), DIS strings, and all
    // readable CHORD characteristics after pairing finishes.
    await sync();

    // Follow-up check after OS ASHA / LE Audio profile handshake completes
    if (Platform.isAndroid) {
      unawaited(_delayedAudioStreamingRefresh(device));
    }
  }

  /// Ensures the device is bonded at the Android OS level and connects the
  /// native `HEARING_AID` (ASHA) and `LE_AUDIO` Bluetooth profiles so media
  /// and phone calls stream to the hearing aid.
  Future<void> _ensureAndroidBondAndAudio(BluetoothDevice device) async {
    try {
      final currentBond = await device.bondState.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => BluetoothBondState.none,
      );
      if (currentBond != BluetoothBondState.bonded) {
        try {
          await device.createBond(timeout: 15);
        } catch (e) {
          debugPrint('createBond note: $e');
        }
      }
    } catch (e) {
      debugPrint('Bond state check note: $e');
    }

    await _invokeNativeAudioConnect(device.remoteId.str);
  }

  Future<bool> _invokeNativeAudioConnect(String address) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _audioChannel.invokeMapMethod<String, dynamic>(
        'ensureBondAndConnectAudio',
        {'address': address},
      );
      final routed = res?['audioOutputConnected'] == true;
      _currentIsSystemAudioRouted = routed;
      _systemAudioRoutedController.add(routed);
      return routed;
    } catch (e) {
      debugPrint('Native audio profile connect note: $e');
      return false;
    }
  }

  Future<void> _delayedAudioStreamingRefresh(BluetoothDevice device) async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!isConnected || _connectedDevice?.remoteId != device.remoteId) return;

    try {
      final routed = await _audioChannel.invokeMethod<bool>(
        'routeAudioToHearingAid',
        {'address': device.remoteId.str},
      );
      if (routed != null) {
        _currentIsSystemAudioRouted = routed;
        _systemAudioRoutedController.add(routed);
      }
    } catch (_) {}

    if (_audioTransportChar != null) {
      try {
        final val = await _safeReadWithRetry(_audioTransportChar!, maxRetries: 2);
        if (val.isNotEmpty) {
          _onAudioTransportBytes(val);
        }
      } catch (_) {}
    }
    if (_connectionStatusChar != null) {
      try {
        final val = await _safeReadWithRetry(
          _connectionStatusChar!,
          maxRetries: 2,
        );
        if (val.isNotEmpty) {
          _onConnectionStatusBytes(val);
        }
      } catch (_) {}
    }
  }

  @override
  Future<bool> enableAudioStreaming() async {
    final device = _connectedDevice ?? _lastConnectedDevice;
    if (device == null || !Platform.isAndroid) return false;

    await _ensureAndroidBondAndAudio(device);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    var routed = false;
    try {
      routed = await _audioChannel.invokeMethod<bool>(
            'routeAudioToHearingAid',
            {'address': device.remoteId.str},
          ) ??
          false;
      _currentIsSystemAudioRouted = routed;
      _systemAudioRoutedController.add(routed);
    } catch (_) {}

    if (isConnected) {
      if (_audioTransportChar != null) {
        try {
          final val = await _safeReadWithRetry(
            _audioTransportChar!,
            maxRetries: 2,
          );
          if (val.isNotEmpty) _onAudioTransportBytes(val);
        } catch (_) {}
      }
      if (_connectionStatusChar != null) {
        try {
          final val = await _safeReadWithRetry(
            _connectionStatusChar!,
            maxRetries: 2,
          );
          if (val.isNotEmpty) _onConnectionStatusBytes(val);
        } catch (_) {}
      }
    }

    return routed || _currentAudioTransport != ChordAudioTransport.none;
  }

  @override
  Future<void> openSystemBluetoothSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _audioChannel.invokeMethod<bool>('openBluetoothSettings');
    } catch (e) {
      debugPrint('Failed to open Bluetooth settings: $e');
    }
  }

  Future<void> _setupCharacteristicsAndSubscriptions(
    List<BluetoothService> services,
  ) async {
    for (final service in services) {
      if (ChordBleConstants.isChordService(service.uuid)) {
        for (final c in service.characteristics) {
          if (ChordBleConstants.matchesCustom(c.uuid, '0002')) {
            _volumeChar = c;
            await _subscribeToCharacteristic(c, _onVolumeBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '000d')) {
            _muteChar = c;
            await _subscribeToCharacteristic(c, _onMuteBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '0005')) {
            _profileChar = c;
            await _subscribeToCharacteristic(c, _onProfileBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '0007')) {
            _micModeChar = c;
            await _subscribeToCharacteristic(c, _onMicModeBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '0004')) {
            _chargingStatusChar = c;
            await _subscribeToCharacteristic(c, _onChargingStatusBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '0009')) {
            _deviceStatusChar = c;
            await _subscribeToCharacteristic(c, _onDeviceStatusBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '0006')) {
            _connectionStatusChar = c;
            await _subscribeToCharacteristic(c, _onConnectionStatusBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '000c')) {
            _audioTransportChar = c;
            await _subscribeToCharacteristic(c, _onAudioTransportBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '000f')) {
            _earpieceStateChar = c;
            await _subscribeToCharacteristic(c, _onEarpieceStateBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '0010')) {
            _faultCodeChar = c;
            await _subscribeToCharacteristic(c, _onFaultCodeBytes);
          } else if (ChordBleConstants.matchesCustom(c.uuid, '0008')) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _otaProgressController.add(value[0]);
              }
            });
          } else if (ChordBleConstants.matchesCustom(c.uuid, '000e')) {
            _firmwareVersionChar = c;
          } else if (ChordBleConstants.matchesCustom(c.uuid, '000b')) {
            _controlPointChar = c;
            await _subscribeToCharacteristic(c, (value) {
              // Indication reply: 2 bytes {opcode, status}
              if (value.length >= 2) {
                final opcode = value[0];
                final status = ChordControlStatus.fromValue(value[1]);
                _controlResponseController.add(MapEntry(opcode, status));
              }
            });
          }
        }
      } else if (ChordBleConstants.isBatteryService(service.uuid)) {
        for (final c in service.characteristics) {
          if (ChordBleConstants.isBatteryLevelChar(c.uuid)) {
            _batteryChar = c;
            await _subscribeToCharacteristic(c, _onBatteryBytes);
          }
        }
      } else if (ChordBleConstants.isDeviceInfoService(service.uuid)) {
        for (final c in service.characteristics) {
          if (ChordBleConstants.isManufacturerNameChar(c.uuid)) {
            _manufacturerChar = c;
          } else if (ChordBleConstants.isModelNumberChar(c.uuid)) {
            _modelChar = c;
          } else if (ChordBleConstants.isHardwareRevisionChar(c.uuid)) {
            _hardwareRevisionChar = c;
          }
        }
      } else if (ChordBleConstants.isSmpService(service.uuid)) {
        for (final c in service.characteristics) {
          if (ChordBleConstants.isSmpChar(c.uuid)) {
            _smpChar = c;
          }
        }
      }
    }
  }

  void _onBatteryBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentBatteryLevel = value[0].clamp(0, 100);
      _batteryLevelController.add(_currentBatteryLevel);
    }
  }

  void _onVolumeBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentVolume = value[0];
      _volumeController.add(_currentVolume);
    }
  }

  void _onMuteBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentIsMuted = value[0] == 1;
      _muteController.add(_currentIsMuted);
    }
  }

  void _onProfileBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentProfile = ChordProfile.fromValue(value[0]);
      _profileController.add(_currentProfile);
    }
  }

  void _onMicModeBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentMicMode = ChordMicMode.fromValue(value[0]);
      _micModeController.add(_currentMicMode);
    }
  }

  void _onChargingStatusBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentChargingStatus = ChordChargingStatus.fromValue(value[0]);
      _chargingStatusController.add(_currentChargingStatus);
    }
  }

  void _onDeviceStatusBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentDeviceStatus = ChordDeviceStatus.fromValue(value[0]);
      _deviceStatusController.add(_currentDeviceStatus);
    }
  }

  void _onConnectionStatusBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentConnectionTelemetry =
          ChordConnectionTelemetry.fromValue(value[0]);
      _connectionTelemetryController.add(_currentConnectionTelemetry);
    }
  }

  void _onAudioTransportBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentAudioTransport = ChordAudioTransport.fromValue(value[0]);
      _audioTransportController.add(_currentAudioTransport);
    }
  }

  void _onEarpieceStateBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentEarpieceState = ChordEarpieceState.fromValue(value[0]);
      _earpieceStateController.add(_currentEarpieceState);
    }
  }

  void _onFaultCodeBytes(List<int> value) {
    if (value.isNotEmpty) {
      _currentFaultCode = ChordFaultCode.fromValue(value[0]);
      _faultCodeController.add(_currentFaultCode);
    }
  }

  /// Explicitly reads Battery Level (0x2A19), Firmware Version (9e32000e),
  /// Device Information Service strings (0x2A29, 0x2A24, 0x2A27), and all
  /// readable CHORD telemetry characteristics after pairing completes.
  Future<void> _readAllTelemetry() async {
    Future<void> readAndApply(
      BluetoothCharacteristic? char,
      void Function(List<int>) handler,
    ) async {
      if (char == null || _connectedDevice == null) return;
      try {
        final val = await _safeReadWithRetry(char);
        if (val.isNotEmpty) {
          handler(val);
        }
      } catch (e) {
        debugPrint('Read failed on ${char.uuid}: $e');
      }
    }

    // 1. Battery Level (0x2A19) - live from fuel gauge, notifies only on 1% delta
    await readAndApply(_batteryChar, _onBatteryBytes);

    // 2. Firmware Version (9e32000e) - 3 raw bytes {major, minor, patch}
    await readAndApply(_firmwareVersionChar, (val) {
      final formatted = ChordBleConstants.formatFirmwareVersion(val);
      if (formatted.isNotEmpty) {
        _currentFirmwareVersion = formatted;
        _firmwareVersionController.add(_currentFirmwareVersion);
      }
    });

    // 3. Connection Status (9e320006) & Audio Transport (9e32000c)
    await readAndApply(_connectionStatusChar, _onConnectionStatusBytes);
    await readAndApply(_audioTransportChar, _onAudioTransportBytes);

    // 4. Device Information Service (0x180A)
    await readAndApply(_manufacturerChar, (val) {
      final str = utf8.decode(val, allowMalformed: true).trim();
      if (str.isNotEmpty) {
        _currentManufacturer = str;
        _manufacturerController.add(_currentManufacturer);
      }
    });
    await readAndApply(_modelChar, (val) {
      final str = utf8.decode(val, allowMalformed: true).trim();
      if (str.isNotEmpty) {
        _currentModel = str;
        _modelController.add(_currentModel);
      }
    });
    await readAndApply(_hardwareRevisionChar, (val) {
      final str = utf8.decode(val, allowMalformed: true).trim();
      if (str.isNotEmpty) {
        _currentHardwareRevision = str;
        _hardwareRevisionController.add(_currentHardwareRevision);
      }
    });

    // 5. Audio controls & hardware status characteristics
    await readAndApply(_volumeChar, _onVolumeBytes);
    await readAndApply(_muteChar, _onMuteBytes);
    await readAndApply(_profileChar, _onProfileBytes);
    await readAndApply(_micModeChar, _onMicModeBytes);
    await readAndApply(_chargingStatusChar, _onChargingStatusBytes);
    await readAndApply(_deviceStatusChar, _onDeviceStatusBytes);
    await readAndApply(_earpieceStateChar, _onEarpieceStateBytes);
    await readAndApply(_faultCodeChar, _onFaultCodeBytes);
  }

  Future<void> _subscribeToCharacteristic(
    BluetoothCharacteristic characteristic,
    void Function(List<int>) onValue,
  ) async {
    final sub = characteristic.onValueReceived.listen(onValue);
    _characteristicSubscriptions.add(sub);

    for (var i = 0; i < 4; i++) {
      try {
        await characteristic.setNotifyValue(true);
        return;
      } catch (e) {
        if (i == 3) {
          debugPrint(
            'Failed to set notification on ${characteristic.uuid}: $e',
          );
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
      }
    }
  }

  /// Safe read with retry for pairing timing (ATT 0x0F / 0x05)
  Future<List<int>> _safeReadWithRetry(
    BluetoothCharacteristic characteristic, {
    int maxRetries = 5,
  }) async {
    for (var i = 0; i < maxRetries; i++) {
      try {
        return await characteristic.read();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
    }
    return [];
  }

  /// Safe write with response and retry
  Future<void> _safeWriteWithRetry(
    BluetoothCharacteristic? characteristic,
    List<int> bytes, {
    int maxRetries = 3,
  }) async {
    if (characteristic == null || !isConnected) {
      throw StateError('Characteristic not available or device not connected');
    }
    for (var i = 0; i < maxRetries; i++) {
      try {
        await characteristic.write(bytes);
        return;
      } catch (e) {
        if (i == maxRetries - 1) {
          debugPrint('Failed write to ${characteristic.uuid}: $e');
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }
  }

  void _clearCharacteristicCache() {
    for (final sub in _characteristicSubscriptions) {
      sub.cancel();
    }
    _characteristicSubscriptions.clear();
    _volumeChar = null;
    _muteChar = null;
    _profileChar = null;
    _micModeChar = null;
    _chargingStatusChar = null;
    _deviceStatusChar = null;
    _connectionStatusChar = null;
    _audioTransportChar = null;
    _earpieceStateChar = null;
    _faultCodeChar = null;
    _firmwareVersionChar = null;
    _controlPointChar = null;
    _batteryChar = null;
    _manufacturerChar = null;
    _modelChar = null;
    _hardwareRevisionChar = null;
    _smpChar = null;
  }

  @override
  Future<void> disconnect() async {
    _clearCharacteristicCache();
    final deviceToDisconnect = _connectedDevice;
    _connectedDevice = null;
    _currentConnectionState = BluetoothConnectionState.disconnected;
    _currentConnectionTelemetry = ChordConnectionTelemetry.disconnected;
    _currentIsSystemAudioRouted = false;
    _connectionStateController.add(BluetoothConnectionState.disconnected);
    _systemAudioRoutedController.add(false);
    if (deviceToDisconnect != null) {
      try {
        await deviceToDisconnect.disconnect();
      } catch (_) {}
    }
  }

  @override
  Future<void> setVolume(int step) async {
    final clamped = step.clamp(1, 10);
    await _safeWriteWithRetry(_volumeChar, [clamped]);
    _currentVolume = clamped;
    _volumeController.add(_currentVolume);
  }

  @override
  Future<void> setMute(bool mute) async {
    await _safeWriteWithRetry(_muteChar, [if (mute) 1 else 0]);
    _currentIsMuted = mute;
    _muteController.add(_currentIsMuted);
  }

  @override
  Future<void> setProfile(ChordProfile profile) async {
    await _safeWriteWithRetry(_profileChar, [profile.value]);
    _currentProfile = profile;
    _profileController.add(_currentProfile);
  }

  @override
  Future<void> setMicMode(ChordMicMode mode) async {
    await _safeWriteWithRetry(_micModeChar, [mode.value]);
    _currentMicMode = mode;
    _micModeController.add(_currentMicMode);
  }

  Future<void> _sendCommand(int opcode) async {
    await _safeWriteWithRetry(_controlPointChar, [opcode]);
  }

  @override
  Future<void> sync() async {
    await _sendCommand(ChordOpcode.sync);
    await _readAllTelemetry();
  }

  @override
  Future<void> reboot() async => _sendCommand(ChordOpcode.reboot);

  @override
  Future<void> factoryReset() async => _sendCommand(ChordOpcode.factoryReset);

  @override
  Future<void> forgetAllPhones() async =>
      _sendCommand(ChordOpcode.forgetAllPhones);

  @override
  Future<void> powerOff() async => _sendCommand(ChordOpcode.powerOff);

  @override
  Future<void> openPairingMode() async =>
      _sendCommand(ChordOpcode.openPairingMode);

  @override
  Future<void> requestStatus() async => sync();

  void dispose() {
    _clearCharacteristicCache();
    _connectionStateSubscription?.cancel();
    _connectionStateController.close();
    _batteryLevelController.close();
    _volumeController.close();
    _muteController.close();
    _profileController.close();
    _micModeController.close();
    _chargingStatusController.close();
    _deviceStatusController.close();
    _connectionTelemetryController.close();
    _audioTransportController.close();
    _earpieceStateController.close();
    _faultCodeController.close();
    _otaProgressController.close();
    _firmwareVersionController.close();
    _hardwareRevisionController.close();
    _manufacturerController.close();
    _modelController.close();
    _controlResponseController.close();
    _systemAudioRoutedController.close();
  }
}
