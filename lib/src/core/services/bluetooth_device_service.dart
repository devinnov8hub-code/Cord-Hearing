import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum MicMode { normal, directional, omni, noiseReduction }

/// Provider for the DeviceRepository.
/// You can easily swap [BluetoothDeviceService] with MockDeviceRepository for UI testing.
final deviceRepositoryProvider = Provider<BluetoothDeviceRepository>((ref) {
  return BluetoothDeviceService();
});

abstract class BluetoothDeviceRepository {
  Stream<int> get batteryLevel;
  Stream<BluetoothConnectionState> get connectionState;

  /// Identifies the currently connected device
  BluetoothDevice? get connectedDevice;

  Future<bool> checkAndRequestPermissions();
  Future<void> connect(BluetoothDevice device);
  Future<void> disconnect();
  Future<void> setVolume(int step);
  Future<void> setMicMode(MicMode mode);
  Future<void> requestStatus();
}

class BluetoothDeviceService implements BluetoothDeviceRepository {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  final _batteryLevelController = StreamController<int>.broadcast();
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();

  @override
  Stream<int> get batteryLevel => _batteryLevelController.stream;

  @override
  Stream<BluetoothConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  BluetoothDevice? get connectedDevice => _connectedDevice;

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
    // On iOS, CoreBluetooth automatically requests permissions when you try to use Bluetooth.
    return true;
  }

  @override
  Future<void> connect(BluetoothDevice device) async {
    // Stop scanning before connecting to avoid Android GATT Error 133
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    // Fix for GATT Error 133
    await device.disconnect();
    await Future<void>.delayed(const Duration(seconds: 1));

    await device.connect(autoConnect: true, mtu: null);
    _connectedDevice = device;

    // Listen to connection state changes
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);

      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
      }
    });

    await device.discoverServices();
    // Subscribe to battery characteristic
    // final batteryService = device.servicesList.firstWhere(
    //   (s) => s.uuid.toString() == '0000180f-0000-1000-8000-00805f9b34fb',
    // );
    // final batteryCharacteristic = batteryService.characteristics.firstWhere(
    //   (c) => c.uuid.toString() == '00002a19-0000-1000-8000-00805f9b34fb',
    // );
    // await batteryCharacteristic.setNotifyValue(true);
    // batteryCharacteristic.lastValueStream.listen((value) {
    //   if (value.isNotEmpty) {
    //     _batteryLevelController.add(value[0]);
    //   }
    // });
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  @override
  Future<void> setVolume(int step) async {
    if (_connectedDevice == null) return;

    // TODO(cord): Write step value to the specific volume GATT characteristic
  }

  @override
  Future<void> setMicMode(MicMode mode) async {
    if (_connectedDevice == null) return;
    // TODO(cord): Write mode value to the specific mic mode GATT characteristic
  }

  @override
  Future<void> requestStatus() async {
    if (_connectedDevice == null) return;
    // TODO(cord): Read status/battery characteristics to update streams
  }

  void dispose() {
    _connectionStateSubscription?.cancel();
    _batteryLevelController.close();
    _connectionStateController.close();
  }
}
