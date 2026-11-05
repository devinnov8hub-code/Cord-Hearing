import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

export 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
export 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show BluetoothConnectionState, BluetoothDevice, Guid;

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

  /// Whether the device is currently connected
  bool get isConnected;

  /// Current connection state
  BluetoothConnectionState get currentConnectionState;

  /// Current battery level (0-100%)
  int get currentBatteryLevel;

  /// Current telemetry connection status
  ChordConnectionTelemetry get currentConnectionTelemetry;

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

  /// Permissions & discovery
  Future<bool> checkAndRequestPermissions();
  Future<List<BluetoothDevice>> getSystemConnectedDevices();

  /// Lifecycle
  Future<void> connect(BluetoothDevice device);
  Future<void> disconnect();

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
  BluetoothDevice? _connectedDevice;
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

  // Cached values
  BluetoothConnectionState _currentConnectionState =
      BluetoothConnectionState.disconnected;
  int _currentBatteryLevel = 0;
  ChordConnectionTelemetry _currentConnectionTelemetry =
      ChordConnectionTelemetry.disconnected;
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

  // Cached characteristics for fast access
  BluetoothCharacteristic? _volumeChar;
  BluetoothCharacteristic? _muteChar;
  BluetoothCharacteristic? _profileChar;
  BluetoothCharacteristic? _micModeChar;
  BluetoothCharacteristic? _controlPointChar;
  BluetoothCharacteristic? _batteryChar;

  @override
  BluetoothDevice? get connectedDevice => _connectedDevice;

  @override
  bool get isConnected =>
      _connectedDevice != null &&
      (_currentConnectionState == BluetoothConnectionState.connected ||
          _currentConnectionTelemetry !=
              ChordConnectionTelemetry.disconnected);

  @override
  BluetoothConnectionState get currentConnectionState =>
      _currentConnectionState;

  @override
  int get currentBatteryLevel => _currentBatteryLevel;

  @override
  ChordConnectionTelemetry get currentConnectionTelemetry =>
      _currentConnectionTelemetry;

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
    try {
      final devices = await FlutterBluePlus.systemDevices([
        ChordBleConstants.chordControlServiceUuid,
      ]);
      return devices;
    } catch (e) {
      debugPrint('Error retrieving system connected devices: $e');
      return [];
    }
  }

  @override
  Future<void> connect(BluetoothDevice device) async {
    // 1. Stop scanning before connecting to avoid Android GATT Error 133
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    _clearCharacteristicCache();

    // Clean up previous connection if any
    try {
      await device.disconnect();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Connect with autoConnect default false
    await device.connect(mtu: null);
    _connectedDevice = device;
    _currentConnectionState = BluetoothConnectionState.connected;
    _currentConnectionTelemetry = ChordConnectionTelemetry.connected;
    _connectionStateController.add(BluetoothConnectionState.connected);

    // Listen to device connection state changes
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen((state) {
      _currentConnectionState = state;
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        _currentConnectionTelemetry = ChordConnectionTelemetry.disconnected;
        _clearCharacteristicCache();
      }
    });

    // Request ATT MTU up to 498 as specified in Chord tech reference
    try {
      await device.requestMtu(498);
    } catch (e) {
      debugPrint('MTU request error: $e');
    }

    // Discover services
    final services = await device.discoverServices();
    await _setupCharacteristicsAndSubscriptions(services);

    // Initial sync: Write 0x01 to Control Point (000b)
    // The device will reply OK and burst every value (one every 20ms)
    await sync();
  }

  Future<void> _setupCharacteristicsAndSubscriptions(
    List<BluetoothService> services,
  ) async {
    for (final service in services) {
      if (ChordBleConstants.isChordService(service.uuid)) {
        for (final c in service.characteristics) {
          final uuidStr = c.uuid.str.toLowerCase();
          if (c.uuid == ChordBleConstants.volumeCharacteristicUuid ||
              uuidStr.contains('0002')) {
            _volumeChar = c;
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentVolume = value[0];
                _volumeController.add(_currentVolume);
              }
            });
          } else if (c.uuid == ChordBleConstants.muteCharacteristicUuid ||
              uuidStr.contains('000d')) {
            _muteChar = c;
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentIsMuted = value[0] == 1;
                _muteController.add(_currentIsMuted);
              }
            });
          } else if (c.uuid ==
                  ChordBleConstants.activeProfileCharacteristicUuid ||
              uuidStr.contains('0005')) {
            _profileChar = c;
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentProfile = ChordProfile.fromValue(value[0]);
                _profileController.add(_currentProfile);
              }
            });
          } else if (c.uuid == ChordBleConstants.micModeCharacteristicUuid ||
              uuidStr.contains('0007')) {
            _micModeChar = c;
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentMicMode = ChordMicMode.fromValue(value[0]);
                _micModeController.add(_currentMicMode);
              }
            });
          } else if (c.uuid ==
                  ChordBleConstants.chargingStatusCharacteristicUuid ||
              uuidStr.contains('0004')) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentChargingStatus = ChordChargingStatus.fromValue(
                  value[0],
                );
                _chargingStatusController.add(_currentChargingStatus);
              }
            });
          } else if (c.uuid ==
                  ChordBleConstants.deviceStatusCharacteristicUuid ||
              uuidStr.contains('0009')) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _deviceStatusController.add(
                  ChordDeviceStatus.fromValue(value[0]),
                );
              }
            });
          } else if (c.uuid ==
                  ChordBleConstants.connectionStatusCharacteristicUuid ||
              uuidStr.contains('0006')) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentConnectionTelemetry =
                    ChordConnectionTelemetry.fromValue(value[0]);
                _connectionTelemetryController.add(_currentConnectionTelemetry);
                if (_currentConnectionTelemetry !=
                    ChordConnectionTelemetry.disconnected) {
                  _currentConnectionState = BluetoothConnectionState.connected;
                  _connectionStateController.add(
                    BluetoothConnectionState.connected,
                  );
                } else if (_currentConnectionState ==
                    BluetoothConnectionState.connected) {
                  _currentConnectionState =
                      BluetoothConnectionState.disconnected;
                  _connectionStateController.add(
                    BluetoothConnectionState.disconnected,
                  );
                }
              }
            });
          } else if (c.uuid ==
                  ChordBleConstants.audioTransportCharacteristicUuid ||
              uuidStr.contains('000c')) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentAudioTransport = ChordAudioTransport.fromValue(
                  value[0],
                );
                _audioTransportController.add(_currentAudioTransport);
              }
            });
          } else if (c.uuid ==
                  ChordBleConstants.earpieceStateCharacteristicUuid ||
              uuidStr.contains('000f')) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentEarpieceState = ChordEarpieceState.fromValue(value[0]);
                _earpieceStateController.add(_currentEarpieceState);
              }
            });
          } else if (c.uuid == ChordBleConstants.faultCodeCharacteristicUuid ||
              uuidStr.contains('0010')) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentFaultCode = ChordFaultCode.fromValue(value[0]);
                _faultCodeController.add(_currentFaultCode);
              }
            });
            try {
              final val = await _safeReadWithRetry(c);
              if (val.isNotEmpty) {
                _currentFaultCode = ChordFaultCode.fromValue(val[0]);
                _faultCodeController.add(_currentFaultCode);
              }
            } catch (_) {}
          } else if (c.uuid ==
                  ChordBleConstants.otaProgressCharacteristicUuid ||
              uuidStr.contains('0008')) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _otaProgressController.add(value[0]);
              }
            });
          } else if (c.uuid ==
                  ChordBleConstants.firmwareVersionCharacteristicUuid ||
              uuidStr.contains('000e')) {
            try {
              final val = await _safeReadWithRetry(c);
              if (val.isNotEmpty) {
                _currentFirmwareVersion = utf8.decode(
                  val,
                  allowMalformed: true,
                );
                _firmwareVersionController.add(_currentFirmwareVersion);
              }
            } catch (e) {
              debugPrint('Error reading firmware version: $e');
            }
          } else if (c.uuid ==
                  ChordBleConstants.controlPointCharacteristicUuid ||
              uuidStr.contains('000b')) {
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
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentBatteryLevel = value[0];
                _batteryLevelController.add(_currentBatteryLevel);
              }
            });
            // Try initial read
            try {
              final val = await _safeReadWithRetry(c);
              if (val.isNotEmpty) {
                _currentBatteryLevel = val[0];
                _batteryLevelController.add(_currentBatteryLevel);
              }
            } catch (e) {
              debugPrint('Initial battery level read failed: $e');
            }
          }
        }
      } else if (ChordBleConstants.isDeviceInfoService(service.uuid)) {
        for (final c in service.characteristics) {
          if (ChordBleConstants.isManufacturerNameChar(c.uuid)) {
            try {
              final val = await _safeReadWithRetry(c);
              if (val.isNotEmpty) {
                _currentManufacturer = utf8.decode(val, allowMalformed: true);
                _manufacturerController.add(_currentManufacturer);
              }
            } catch (_) {}
          } else if (ChordBleConstants.isModelNumberChar(c.uuid)) {
            try {
              final val = await _safeReadWithRetry(c);
              if (val.isNotEmpty) {
                _currentModel = utf8.decode(val, allowMalformed: true);
                _modelController.add(_currentModel);
              }
            } catch (_) {}
          } else if (ChordBleConstants.isHardwareRevisionChar(c.uuid)) {
            try {
              final val = await _safeReadWithRetry(c);
              if (val.isNotEmpty) {
                _currentHardwareRevision =
                    utf8.decode(val, allowMalformed: true);
                _hardwareRevisionController.add(_currentHardwareRevision);
              }
            } catch (_) {}
          }
        }
      }
    }
  }

  Future<void> _subscribeToCharacteristic(
    BluetoothCharacteristic characteristic,
    void Function(List<int>) onValue,
  ) async {
    try {
      await characteristic.setNotifyValue(true);
      final sub = characteristic.lastValueStream.listen(onValue);
      _characteristicSubscriptions.add(sub);
    } catch (e) {
      debugPrint('Failed to set notification on ${characteristic.uuid}: $e');
    }
  }

  /// Safe read with retry for pairing timing (ATT 0x0F / 0x05)
  Future<List<int>> _safeReadWithRetry(
    BluetoothCharacteristic characteristic, {
    int maxRetries = 3,
  }) async {
    for (var i = 0; i < maxRetries; i++) {
      try {
        return await characteristic.read();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    return [];
  }

  /// Safe write with response and retry
  Future<void> _safeWriteWithRetry(
    BluetoothCharacteristic? characteristic,
    List<int> bytes, {
    int maxRetries = 2,
  }) async {
    if (characteristic == null) return;
    for (var i = 0; i < maxRetries; i++) {
      try {
        await characteristic.write(bytes);
        return;
      } catch (e) {
        if (i == maxRetries - 1) {
          debugPrint('Failed write to ${characteristic.uuid}: $e');
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
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
    _controlPointChar = null;
    _batteryChar = null;
  }

  @override
  Future<void> disconnect() async {
    _clearCharacteristicCache();
    _currentConnectionState = BluetoothConnectionState.disconnected;
    _currentConnectionTelemetry = ChordConnectionTelemetry.disconnected;
    _connectionStateController.add(BluetoothConnectionState.disconnected);
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
    }
  }

  @override
  Future<void> setVolume(int step) async {
    final clamped = step.clamp(1, 10);
    await _safeWriteWithRetry(_volumeChar, [clamped]);
  }

  @override
  Future<void> setMute(bool mute) async {
    await _safeWriteWithRetry(_muteChar, [if (mute) 1 else 0]);
  }

  @override
  Future<void> setProfile(ChordProfile profile) async {
    await _safeWriteWithRetry(_profileChar, [profile.value]);
  }

  @override
  Future<void> setMicMode(ChordMicMode mode) async {
    await _safeWriteWithRetry(_micModeChar, [mode.value]);
  }

  Future<void> _sendCommand(int opcode) async {
    if (_controlPointChar == null) return;
    await _safeWriteWithRetry(_controlPointChar, [opcode]);
  }

  @override
  Future<void> sync() async {
    await _sendCommand(ChordOpcode.sync);
    if (_batteryChar != null) {
      try {
        final val = await _safeReadWithRetry(_batteryChar!);
        if (val.isNotEmpty) {
          _currentBatteryLevel = val[0];
          _batteryLevelController.add(_currentBatteryLevel);
        }
      } catch (e) {
        debugPrint('Battery re-read on sync error: $e');
      }
    }
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
  }
}
