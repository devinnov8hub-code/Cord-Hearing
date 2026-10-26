import 'dart:async';

import 'package:cord_hearing/src/core/services/bluetooth_device_service.dart';
import 'package:flutter/foundation.dart';
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
    this.systemDevices = const [],
    this.errorMessage,
    this.requiresPairingMode = false,
  });

  final BluetoothScanStatus status;
  final List<ScanResult> devices;
  final List<BluetoothDevice> systemDevices;
  final String? errorMessage;
  final bool requiresPairingMode;

  DevicePairingState copyWith({
    BluetoothScanStatus? status,
    List<ScanResult>? devices,
    List<BluetoothDevice>? systemDevices,
    String? errorMessage,
    bool? requiresPairingMode,
    bool clearError = false,
  }) {
    return DevicePairingState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      systemDevices: systemDevices ?? this.systemDevices,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      requiresPairingMode: requiresPairingMode ?? this.requiresPairingMode,
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
      // Prioritize CHORD hearing aid devices in scan results
      final sortedResults = List<ScanResult>.from(results)
        ..sort((a, b) {
          final aIsChord =
              a.device.platformName.contains('CHORD') ||
              a.advertisementData.serviceUuids.contains(
                ChordBleConstants.chordControlServiceUuid,
              );
          final bIsChord =
              b.device.platformName.contains('CHORD') ||
              b.advertisementData.serviceUuids.contains(
                ChordBleConstants.chordControlServiceUuid,
              );
          if (aIsChord && !bIsChord) return -1;
          if (!aIsChord && bIsChord) return 1;
          return b.rssi.compareTo(a.rssi);
        });

      state = state.copyWith(devices: sortedResults);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning && state.status == BluetoothScanStatus.scanning) {
        state = state.copyWith(status: BluetoothScanStatus.scanned);
      }
    });

    // Check system devices immediately
    _checkSystemDevices();

    return DevicePairingState();
  }

  Future<void> _checkSystemDevices() async {
    final repository = ref.read(deviceRepositoryProvider);
    final systemDevices = await repository.getSystemConnectedDevices();
    if (systemDevices.isNotEmpty) {
      state = state.copyWith(systemDevices: systemDevices);
    }
  }

  Future<void> startScan() async {
    state = state.copyWith(clearError: true, requiresPairingMode: false);
    final repository = ref.read(deviceRepositoryProvider);
    final hasPermissions = await repository.checkAndRequestPermissions();
    if (!hasPermissions) {
      state = state.copyWith(
        status: BluetoothScanStatus.error,
        errorMessage: 'Bluetooth and Location permissions are required.',
      );
      return;
    }

    if (await FlutterBluePlus.isSupported == false) {
      state = state.copyWith(
        status: BluetoothScanStatus.error,
        errorMessage: 'Bluetooth is not supported on this device.',
      );
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      state = state.copyWith(
        status: BluetoothScanStatus.error,
        errorMessage: 'Please turn on Bluetooth to connect your hearing aid.',
      );
      return;
    }

    // Check system devices first (LE Audio / ASHA system streaming)
    await _checkSystemDevices();

    state = state.copyWith(status: BluetoothScanStatus.scanning, devices: []);
    try {
      FlutterBluePlus.setLogLevel(LogLevel.verbose);
      await FlutterBluePlus.startScan(
        withServices: [ChordBleConstants.chordControlServiceUuid],
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Specific UUID scan error, falling back to general scan: $e');
      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      } catch (err) {
        state = state.copyWith(
          status: BluetoothScanStatus.error,
          errorMessage: err.toString(),
        );
      }
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    state = state.copyWith(
      status: BluetoothScanStatus.connecting,
      clearError: true,
      requiresPairingMode: false,
    );

    final connectStartTime = DateTime.now();
    StreamSubscription<BluetoothConnectionState>? quickDropSub;

    try {
      final repository = ref.read(deviceRepositoryProvider);

      // Listen for fast disconnect (spec: unbonded phone disconnects in ~1 sec if not in pairing mode)
      quickDropSub = device.connectionState.listen((connState) {
        if (connState == BluetoothConnectionState.disconnected) {
          final elapsed = DateTime.now().difference(connectStartTime);
          if (elapsed.inMilliseconds < 2500 &&
              state.status == BluetoothScanStatus.connecting) {
            state = state.copyWith(
              status: BluetoothScanStatus.error,
              requiresPairingMode: true,
              errorMessage:
                  'Device disconnected immediately. Please hold VOL+ and VOL− together for 3 seconds on your CHORD unit to enter Pairing Mode.',
            );
          }
        }
      });

      await repository.connect(device);
      await quickDropSub.cancel();

      state = state.copyWith(status: BluetoothScanStatus.connected);
    } catch (e) {
      await quickDropSub?.cancel();
      final elapsed = DateTime.now().difference(connectStartTime);
      if (elapsed.inMilliseconds < 2500) {
        state = state.copyWith(
          status: BluetoothScanStatus.error,
          requiresPairingMode: true,
          errorMessage:
              'Connection dropped. Please press and hold VOL+ and VOL− together for 3 seconds on your CHORD device to enter Pairing Mode.',
        );
      } else {
        state = state.copyWith(
          status: BluetoothScanStatus.error,
          errorMessage: 'Failed to connect: $e',
        );
      }
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
