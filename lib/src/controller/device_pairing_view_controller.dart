import 'dart:async';

import 'package:cord_hearing/src/core/services/bluetooth_device_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      // log(results.toString());
      state = state.copyWith(devices: results);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning && state.status == BluetoothScanStatus.scanning) {
        state = state.copyWith(status: BluetoothScanStatus.scanned);
      }
    });

    return DevicePairingState();
  }

  Future<void> startScan() async {
    state = state.copyWith(clearError: true);
    final repository = ref.read(deviceRepositoryProvider);
    final hasPermissions = await repository.checkAndRequestPermissions();
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

  Future<void> connectToDevice(BluetoothDevice device) async {
    state = state.copyWith(
      status: BluetoothScanStatus.connecting,
    );
    try {
      final repository = ref.read(deviceRepositoryProvider);
      await repository.connect(device);

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
