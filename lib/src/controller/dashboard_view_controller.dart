import 'dart:async';

import 'package:cord_hearing/src/core/services/bluetooth_device_service.dart';
import 'package:cord_hearing/src/core/services/toast_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardState {
  DashboardState({
    this.batteryLevel = 0,
    this.connectionState = 'Disconnected',
    this.volume = 5,
    this.isMuted = false,
    this.micMode = ChordMicMode.omni,
    this.profile = ChordProfile.normal,
    this.earpieceState = ChordEarpieceState.ready,
    this.faultCode = ChordFaultCode.none,
    this.chargingStatus = ChordChargingStatus.discharging,
    this.audioTransport = ChordAudioTransport.none,
    this.deviceStatus = ChordDeviceStatus.ok,
    this.deviceName = 'Unknown Device',
    this.firmwareVersion = '',
    this.hardwareRevision = '',
    this.manufacturer = '',
    this.model = '',
    this.isStreamingAudio = false,
    this.lastCommandMessage,
  });

  final int batteryLevel;
  final String connectionState;
  final int volume;
  final bool isMuted;
  final ChordMicMode micMode;
  final ChordProfile profile;
  final ChordEarpieceState earpieceState;
  final ChordFaultCode faultCode;
  final ChordChargingStatus chargingStatus;
  final ChordAudioTransport audioTransport;
  final ChordDeviceStatus deviceStatus;
  final String deviceName;
  final String firmwareVersion;
  final String hardwareRevision;
  final String manufacturer;
  final String model;
  final bool isStreamingAudio;
  final String? lastCommandMessage;

  bool get isConnected =>
      !connectionState.toLowerCase().contains('dis') &&
      (connectionState.toLowerCase().contains('conn') ||
          connectionState.toLowerCase().contains('stream'));

  DashboardState copyWith({
    int? batteryLevel,
    String? connectionState,
    int? volume,
    bool? isMuted,
    ChordMicMode? micMode,
    ChordProfile? profile,
    ChordEarpieceState? earpieceState,
    ChordFaultCode? faultCode,
    ChordChargingStatus? chargingStatus,
    ChordAudioTransport? audioTransport,
    ChordDeviceStatus? deviceStatus,
    String? deviceName,
    String? firmwareVersion,
    String? hardwareRevision,
    String? manufacturer,
    String? model,
    bool? isStreamingAudio,
    String? lastCommandMessage,
    bool clearCommandMessage = false,
  }) {
    return DashboardState(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      connectionState: connectionState ?? this.connectionState,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      micMode: micMode ?? this.micMode,
      profile: profile ?? this.profile,
      earpieceState: earpieceState ?? this.earpieceState,
      faultCode: faultCode ?? this.faultCode,
      chargingStatus: chargingStatus ?? this.chargingStatus,
      audioTransport: audioTransport ?? this.audioTransport,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      deviceName: deviceName ?? this.deviceName,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      hardwareRevision: hardwareRevision ?? this.hardwareRevision,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      isStreamingAudio: isStreamingAudio ?? this.isStreamingAudio,
      lastCommandMessage: clearCommandMessage
          ? null
          : (lastCommandMessage ?? this.lastCommandMessage),
    );
  }
}

class DashboardViewController extends AutoDisposeNotifier<DashboardState> {
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  DashboardState build() {
    final repo = ref.read(deviceRepositoryProvider);

    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
    });

    _subscriptions.addAll([
      repo.batteryLevel.listen((level) {
        state = state.copyWith(
          batteryLevel: level,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.connectionState.listen((status) {
        final isConn = status == BluetoothConnectionState.connected;
        final dev = repo.connectedDevice ?? repo.lastConnectedDevice;
        final devName = (dev != null && dev.platformName.isNotEmpty)
            ? dev.platformName
            : state.deviceName;
        state = state.copyWith(
          connectionState: isConn ? 'Connected' : 'Disconnected',
          isStreamingAudio: isConn && state.isStreamingAudio,
          deviceName: devName,
        );
      }),
      repo.volume.listen((vol) {
        state = state.copyWith(
          volume: vol,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.isMuted.listen((muted) {
        state = state.copyWith(
          isMuted: muted,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.activeProfile.listen((p) {
        state = state.copyWith(
          profile: p,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.micMode.listen((mode) {
        state = state.copyWith(
          micMode: mode,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.chargingStatus.listen((status) {
        state = state.copyWith(
          chargingStatus: status,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.deviceStatus.listen((status) {
        state = state.copyWith(
          deviceStatus: status,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.earpieceState.listen((earpiece) {
        state = state.copyWith(
          earpieceState: earpiece,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.faultCode.listen((fault) {
        state = state.copyWith(
          faultCode: fault,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.audioTransport.listen((transport) {
        state = state.copyWith(
          audioTransport: transport,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.connectionTelemetry.listen((telemetry) {
        final isStreaming =
            telemetry == ChordConnectionTelemetry.streamingAudio;
        final isConnected =
            repo.isConnected ||
            telemetry != ChordConnectionTelemetry.disconnected;
        state = state.copyWith(
          isStreamingAudio: isStreaming,
          connectionState: isConnected ? 'Connected' : 'Disconnected',
        );
      }),
      repo.firmwareVersion.listen((version) {
        state = state.copyWith(
          firmwareVersion: version,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.hardwareRevision.listen((hwRev) {
        state = state.copyWith(
          hardwareRevision: hwRev,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.manufacturerName.listen((mfg) {
        state = state.copyWith(
          manufacturer: mfg,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.modelNumber.listen((model) {
        state = state.copyWith(
          model: model,
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
      repo.controlResponses.listen((entry) {
        state = state.copyWith(
          lastCommandMessage:
              'Command 0x${entry.key.toRadixString(16)}: ${entry.value.description}',
          connectionState: repo.isConnected ? 'Connected' : state.connectionState,
        );
      }),
    ]);

    final device = repo.connectedDevice ?? repo.lastConnectedDevice;
    var name = 'CHORD Body Unit';
    if (device != null) {
      name = device.platformName.isNotEmpty
          ? device.platformName
          : device.remoteId.str;
    }

    final isDeviceConnected = repo.isConnected;

    // Initialize with cached repo values
    final initial = DashboardState(
      deviceName: name,
      connectionState: isDeviceConnected ? 'Connected' : 'Disconnected',
      batteryLevel: repo.currentBatteryLevel,
      volume: repo.currentVolume,
      isMuted: repo.currentIsMuted,
      profile: repo.currentProfile,
      micMode: repo.currentMicMode,
      earpieceState: repo.currentEarpieceState,
      faultCode: repo.currentFaultCode,
      chargingStatus: repo.currentChargingStatus,
      audioTransport: repo.currentAudioTransport,
      deviceStatus: repo.currentDeviceStatus,
      firmwareVersion: repo.currentFirmwareVersion,
      hardwareRevision: repo.currentHardwareRevision,
      manufacturer: repo.currentManufacturer,
      model: repo.currentModel,
      isStreamingAudio: isDeviceConnected &&
          repo.currentConnectionTelemetry ==
              ChordConnectionTelemetry.streamingAudio,
    );

    // Trigger full sync if connected
    if (isDeviceConnected) {
      repo.sync();
    }

    return initial;
  }

  Future<void> disconnect() async {
    await ref.read(deviceRepositoryProvider).disconnect();
    state = state.copyWith(
      connectionState: 'Disconnected',
      isStreamingAudio: false,
    );
  }

  Future<bool> reconnect() async {
    final repo = ref.read(deviceRepositoryProvider);
    var target = repo.connectedDevice ?? repo.lastConnectedDevice;
    if (target == null) {
      final sys = await repo.getSystemConnectedDevices();
      if (sys.isNotEmpty) {
        target = sys.first;
      }
    }
    if (target == null) return false;
    await repo.connect(target);
    final connected = repo.isConnected;
    state = state.copyWith(
      connectionState: connected ? 'Connected' : 'Disconnected',
      deviceName: target.platformName.isNotEmpty
          ? target.platformName
          : state.deviceName,
      batteryLevel: repo.currentBatteryLevel,
      firmwareVersion: repo.currentFirmwareVersion,
      hardwareRevision: repo.currentHardwareRevision,
      manufacturer: repo.currentManufacturer,
      model: repo.currentModel,
      audioTransport: repo.currentAudioTransport,
      chargingStatus: repo.currentChargingStatus,
      earpieceState: repo.currentEarpieceState,
      faultCode: repo.currentFaultCode,
      deviceStatus: repo.currentDeviceStatus,
      isStreamingAudio: connected &&
          repo.currentConnectionTelemetry ==
              ChordConnectionTelemetry.streamingAudio,
    );
    return connected;
  }

  Future<void> setVolume(int vol) async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to adjust volume.');
      return;
    }
    if (vol < 1 || vol > 10) return;
    final previous = state.volume;
    state = state.copyWith(volume: vol);
    try {
      await ref.read(deviceRepositoryProvider).setVolume(vol);
    } catch (_) {
      state = state.copyWith(volume: previous);
      Toasts.showError('Failed to sync volume with CHORD device.');
    }
  }

  Future<void> toggleMute() async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to mute or unmute.');
      return;
    }
    final previous = state.isMuted;
    final newMute = !previous;
    state = state.copyWith(isMuted: newMute);
    try {
      await ref.read(deviceRepositoryProvider).setMute(newMute);
    } catch (_) {
      state = state.copyWith(isMuted: previous);
      Toasts.showError('Failed to sync mute state with CHORD device.');
    }
  }

  Future<void> setProfile(ChordProfile profile) async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to change sound profile.');
      return;
    }
    if (state.profile == profile) return;
    final previous = state.profile;
    state = state.copyWith(profile: profile);
    try {
      await ref.read(deviceRepositoryProvider).setProfile(profile);
    } catch (_) {
      state = state.copyWith(profile: previous);
      Toasts.showError('Failed to sync sound profile with CHORD device.');
    }
  }

  Future<void> setMicMode(ChordMicMode mode) async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to change microphone mode.');
      return;
    }
    if (state.micMode == mode) return;
    final previous = state.micMode;
    state = state.copyWith(micMode: mode);
    try {
      await ref.read(deviceRepositoryProvider).setMicMode(mode);
    } catch (_) {
      state = state.copyWith(micMode: previous);
      Toasts.showError('Failed to sync mic mode with CHORD device.');
    }
  }

  Future<void> sync() async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to synchronize.');
      return;
    }
    try {
      await ref.read(deviceRepositoryProvider).sync();
    } catch (_) {
      Toasts.showError('Failed to synchronize with CHORD device.');
    }
  }

  Future<void> rebootDevice() async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to reboot.');
      return;
    }
    try {
      await ref.read(deviceRepositoryProvider).reboot();
    } catch (_) {
      Toasts.showError('Failed to reboot CHORD device.');
    }
  }

  Future<void> factoryReset() async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to factory reset.');
      return;
    }
    try {
      await ref.read(deviceRepositoryProvider).factoryReset();
    } catch (_) {
      Toasts.showError('Failed to factory reset CHORD device.');
    }
  }

  Future<void> forgetAllPhones() async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to forget bonded phones.');
      return;
    }
    try {
      await ref.read(deviceRepositoryProvider).forgetAllPhones();
    } catch (_) {
      Toasts.showError('Failed to forget bonded phones on CHORD device.');
    }
  }

  Future<void> powerOff() async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to power off.');
      return;
    }
    try {
      await ref.read(deviceRepositoryProvider).powerOff();
    } catch (_) {
      Toasts.showError('Failed to power off CHORD device.');
    }
  }

  Future<void> openPairingMode() async {
    if (!state.isConnected) {
      Toasts.showError('Connect your CHORD device to open pairing mode.');
      return;
    }
    try {
      await ref.read(deviceRepositoryProvider).openPairingMode();
    } catch (_) {
      Toasts.showError('Failed to open pairing mode on CHORD device.');
    }
  }
}

final AutoDisposeNotifierProvider<DashboardViewController, DashboardState>
dashboardProvider =
    NotifierProvider.autoDispose<DashboardViewController, DashboardState>(
      DashboardViewController.new,
    );
