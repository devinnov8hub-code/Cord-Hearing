import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

export 'package:cord_hearing/src/core/services/chord_ble_constants.dart';

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
  Stream<int> get otaProgress;
  Stream<String> get firmwareVersion;
  Stream<String> get manufacturerName;
  Stream<String> get modelNumber;
  Stream<MapEntry<int, ChordControlStatus>> get controlResponses;

  // Cached current values for synchronous access
  int get currentVolume;
  bool get currentIsMuted;
  ChordProfile get currentProfile;
  ChordMicMode get currentMicMode;
  ChordEarpieceState get currentEarpieceState;
  ChordChargingStatus get currentChargingStatus;
  ChordAudioTransport get currentAudioTransport;
  String get currentFirmwareVersion;

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
  final _otaProgressController = StreamController<int>.broadcast();
  final _firmwareVersionController = StreamController<String>.broadcast();
  final _manufacturerController = StreamController<String>.broadcast();
  final _modelController = StreamController<String>.broadcast();
  final _controlResponseController =
      StreamController<MapEntry<int, ChordControlStatus>>.broadcast();

  // Cached values
  int _currentVolume = 5;
  bool _currentIsMuted = false;
  ChordProfile _currentProfile = ChordProfile.normal;
  ChordMicMode _currentMicMode = ChordMicMode.omni;
  ChordEarpieceState _currentEarpieceState = ChordEarpieceState.ready;
  ChordChargingStatus _currentChargingStatus = ChordChargingStatus.discharging;
  ChordAudioTransport _currentAudioTransport = ChordAudioTransport.none;
  String _currentFirmwareVersion = '';

  // Cached characteristics for fast access
  BluetoothCharacteristic? _volumeChar;
  BluetoothCharacteristic? _muteChar;
  BluetoothCharacteristic? _profileChar;
  BluetoothCharacteristic? _micModeChar;
  BluetoothCharacteristic? _controlPointChar;

  @override
  BluetoothDevice? get connectedDevice => _connectedDevice;

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
  Stream<int> get otaProgress => _otaProgressController.stream;
  @override
  Stream<String> get firmwareVersion => _firmwareVersionController.stream;
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
  ChordChargingStatus get currentChargingStatus => _currentChargingStatus;
  @override
  ChordAudioTransport get currentAudioTransport => _currentAudioTransport;
  @override
  String get currentFirmwareVersion => _currentFirmwareVersion;

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

    // Listen to device connection state changes
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
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
      if (service.uuid == ChordBleConstants.chordControlServiceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid == ChordBleConstants.volumeCharacteristicUuid) {
            _volumeChar = c;
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentVolume = value[0];
                _volumeController.add(_currentVolume);
              }
            });
          } else if (c.uuid == ChordBleConstants.muteCharacteristicUuid) {
            _muteChar = c;
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentIsMuted = value[0] == 1;
                _muteController.add(_currentIsMuted);
              }
            });
          } else if (c.uuid ==
              ChordBleConstants.activeProfileCharacteristicUuid) {
            _profileChar = c;
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentProfile = ChordProfile.fromValue(value[0]);
                _profileController.add(_currentProfile);
              }
            });
          } else if (c.uuid == ChordBleConstants.micModeCharacteristicUuid) {
            _micModeChar = c;
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentMicMode = ChordMicMode.fromValue(value[0]);
                _micModeController.add(_currentMicMode);
              }
            });
          } else if (c.uuid ==
              ChordBleConstants.chargingStatusCharacteristicUuid) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentChargingStatus = ChordChargingStatus.fromValue(
                  value[0],
                );
                _chargingStatusController.add(_currentChargingStatus);
              }
            });
          } else if (c.uuid ==
              ChordBleConstants.deviceStatusCharacteristicUuid) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _deviceStatusController.add(
                  ChordDeviceStatus.fromValue(value[0]),
                );
              }
            });
          } else if (c.uuid ==
              ChordBleConstants.connectionStatusCharacteristicUuid) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _connectionTelemetryController.add(
                  ChordConnectionTelemetry.fromValue(value[0]),
                );
              }
            });
          } else if (c.uuid ==
              ChordBleConstants.audioTransportCharacteristicUuid) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentAudioTransport = ChordAudioTransport.fromValue(
                  value[0],
                );
                _audioTransportController.add(_currentAudioTransport);
              }
            });
          } else if (c.uuid ==
              ChordBleConstants.earpieceStateCharacteristicUuid) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _currentEarpieceState = ChordEarpieceState.fromValue(value[0]);
                _earpieceStateController.add(_currentEarpieceState);
              }
            });
          } else if (c.uuid ==
              ChordBleConstants.otaProgressCharacteristicUuid) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _otaProgressController.add(value[0]);
              }
            });
          } else if (c.uuid ==
              ChordBleConstants.firmwareVersionCharacteristicUuid) {
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
              ChordBleConstants.controlPointCharacteristicUuid) {
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
      } else if (service.uuid == ChordBleConstants.batteryServiceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid == ChordBleConstants.batteryLevelCharacteristicUuid) {
            await _subscribeToCharacteristic(c, (value) {
              if (value.isNotEmpty) {
                _batteryLevelController.add(value[0]);
              }
            });
            // Try initial read
            try {
              final val = await _safeReadWithRetry(c);
              if (val.isNotEmpty) {
                _batteryLevelController.add(val[0]);
              }
            } catch (_) {}
          }
        }
      } else if (service.uuid ==
          ChordBleConstants.deviceInformationServiceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid == ChordBleConstants.manufacturerNameCharacteristicUuid) {
            try {
              final val = await _safeReadWithRetry(c);
              if (val.isNotEmpty) {
                _manufacturerController.add(
                  utf8.decode(val, allowMalformed: true),
                );
              }
            } catch (_) {}
          } else if (c.uuid ==
              ChordBleConstants.modelNumberCharacteristicUuid) {
            try {
              final val = await _safeReadWithRetry(c);
              if (val.isNotEmpty) {
                _modelController.add(utf8.decode(val, allowMalformed: true));
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
  }

  @override
  Future<void> disconnect() async {
    _clearCharacteristicCache();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
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
  Future<void> sync() async => _sendCommand(ChordOpcode.sync);

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
    _otaProgressController.close();
    _firmwareVersionController.close();
    _manufacturerController.close();
    _modelController.close();
    _controlResponseController.close();
  }
}
