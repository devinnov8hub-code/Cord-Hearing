import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum BluetoothScanStatus {
  idle,
  scanning,
  scanned,
  connecting,
  connected,
  error,
}

class DevicePairingState {
  DevicePairingState({
    this.status = BluetoothScanStatus.idle,
    this.devices = const [],
    this.errorMessage,
  });
  final BluetoothScanStatus status;
  final List<ScanResult> devices;
  final String? errorMessage;

  DevicePairingState copyWith({
    BluetoothScanStatus? status,
    List<ScanResult>? devices,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DevicePairingState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DevicePairingViewController
    extends AutoDisposeNotifier<DevicePairingState> {
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  @override
  DevicePairingState build() {
    ref.onDispose(() {
      _scanResultsSubscription?.cancel();
      _isScanningSubscription?.cancel();
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      // Keep devices updated while scanning
      state = state.copyWith(devices: results);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning && state.status == BluetoothScanStatus.scanning) {
        state = state.copyWith(status: BluetoothScanStatus.scanned);
      }
    });

    return DevicePairingState();
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    }
    // On iOS, CoreBluetooth automatically requests permissions when you try to use Bluetooth.
    // Using permission_handler on iOS requires modifying the Podfile.
    return true;
  }

  Future<void> startScan() async {
    state = state.copyWith(clearError: true);
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      state = state.copyWith(
        status: BluetoothScanStatus.error,
        errorMessage: 'Permissions not granted',
      );
      return;
    }

    if (await FlutterBluePlus.isSupported == false) {
      state = state.copyWith(
        status: BluetoothScanStatus.error,
        errorMessage: 'Bluetooth not supported on this device',
      );
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      state = state.copyWith(
        status: BluetoothScanStatus.error,
        errorMessage: 'Please turn on Bluetooth',
      );
      return;
    }

    state = state.copyWith(status: BluetoothScanStatus.scanning, devices: []);
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    } catch (e) {
      state = state.copyWith(
        status: BluetoothScanStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> connectToDevice(BluetoothDevice? device) async {
    state = state.copyWith(
      status: BluetoothScanStatus.connecting,
    );
    try {
      if (device != null) {
        // Stop scanning before connecting to avoid Android GATT Error 133
        if (FlutterBluePlus.isScanningNow) {
          await FlutterBluePlus.stopScan();
        }
        await device.connect();
      } else {
        // Mock connection
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      state = state.copyWith(status: BluetoothScanStatus.connected);
    } catch (e) {
      state = state.copyWith(
        status: BluetoothScanStatus.error,
        errorMessage: 'Failed to connect: $e',
      );
    }
  }
}

final AutoDisposeNotifierProvider<
  DevicePairingViewController,
  DevicePairingState
>
bluetoothScanProvider =
    NotifierProvider.autoDispose<
      DevicePairingViewController,
      DevicePairingState
    >(
      DevicePairingViewController.new,
    );
