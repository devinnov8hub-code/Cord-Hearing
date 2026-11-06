import 'dart:async';

import 'package:cord_hearing/src/core/services/bluetooth_device_service.dart';
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
          connectionState: 'Connected',
        );
      }),
      repo.connectionState.listen((status) {
        final isConn = status == BluetoothConnectionState.connected;
        state = state.copyWith(
          connectionState: isConn ? 'Connected' : 'Disconnected',
        );
      }),
      repo.volume.listen((vol) {
        state = state.copyWith(
          volume: vol,
          connectionState: 'Connected',
        );
      }),
      repo.isMuted.listen((muted) {
        state = state.copyWith(
          isMuted: muted,
          connectionState: 'Connected',
        );
      }),
      repo.activeProfile.listen((p) {
        state = state.copyWith(
          profile: p,
          connectionState: 'Connected',
        );
      }),
      repo.micMode.listen((mode) {
        state = state.copyWith(
          micMode: mode,
          connectionState: 'Connected',
        );
      }),
      repo.chargingStatus.listen((status) {
        state = state.copyWith(
          chargingStatus: status,
          connectionState: 'Connected',
        );
      }),
      repo.deviceStatus.listen((status) {
        state = state.copyWith(
          deviceStatus: status,
          connectionState: 'Connected',
        );
      }),
      repo.earpieceState.listen((earpiece) {
        state = state.copyWith(
          earpieceState: earpiece,
          connectionState: 'Connected',
        );
      }),
      repo.faultCode.listen((fault) {
        state = state.copyWith(
          faultCode: fault,
          connectionState: 'Connected',
        );
      }),
      repo.audioTransport.listen((transport) {
        state = state.copyWith(
          audioTransport: transport,
          connectionState: 'Connected',
        );
      }),
      repo.connectionTelemetry.listen((telemetry) {
        final isStreaming =
            telemetry == ChordConnectionTelemetry.streamingAudio;
        final isConnected =
            telemetry != ChordConnectionTelemetry.disconnected;
        state = state.copyWith(
          isStreamingAudio: isStreaming,
          connectionState: isConnected ? 'Connected' : 'Disconnected',
        );
      }),
      repo.firmwareVersion.listen((version) {
        state = state.copyWith(
          firmwareVersion: version,
          connectionState: 'Connected',
        );
      }),
      repo.hardwareRevision.listen((hwRev) {
        state = state.copyWith(
          hardwareRevision: hwRev,
          connectionState: 'Connected',
        );
      }),
      repo.manufacturerName.listen((mfg) {
        state = state.copyWith(
          manufacturer: mfg,
          connectionState: 'Connected',
        );
      }),
      repo.modelNumber.listen((model) {
        state = state.copyWith(
          model: model,
          connectionState: 'Connected',
        );
      }),
      repo.controlResponses.listen((entry) {
        state = state.copyWith(
          lastCommandMessage:
              'Command 0x${entry.key.toRadixString(16)}: ${entry.value.description}',
          connectionState: 'Connected',
        );
      }),
    ]);

    final device = repo.connectedDevice;
    var name = 'CHORD Body Unit';
    if (device != null) {
      name = device.platformName.isNotEmpty
          ? device.platformName
          : device.remoteId.str;
    }

    final isDeviceConnected = repo.isConnected ||
        repo.currentConnectionState == BluetoothConnectionState.connected ||
        device != null;

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
      firmwareVersion: repo.currentFirmwareVersion,
      hardwareRevision: repo.currentHardwareRevision,
      manufacturer: repo.currentManufacturer,
      model: repo.currentModel,
      isStreamingAudio: repo.currentConnectionTelemetry ==
          ChordConnectionTelemetry.streamingAudio,
    );

    // Trigger full sync if connected
    if (isDeviceConnected) {
      repo.sync();
    }

    return initial;
  }

  void setVolume(int vol) {
    if (vol < 1 || vol > 10) return;
    state = state.copyWith(volume: vol);
    ref.read(deviceRepositoryProvider).setVolume(vol);
  }

  void toggleMute() {
    final newMute = !state.isMuted;
    state = state.copyWith(isMuted: newMute);
    ref.read(deviceRepositoryProvider).setMute(newMute);
  }

  void setProfile(ChordProfile profile) {
    state = state.copyWith(profile: profile);
    ref.read(deviceRepositoryProvider).setProfile(profile);
  }

  void setMicMode(ChordMicMode mode) {
    state = state.copyWith(micMode: mode);
    ref.read(deviceRepositoryProvider).setMicMode(mode);
  }

  void sync() {
    ref.read(deviceRepositoryProvider).sync();
  }

  void rebootDevice() {
    ref.read(deviceRepositoryProvider).reboot();
  }

  void factoryReset() {
    ref.read(deviceRepositoryProvider).factoryReset();
  }

  void forgetAllPhones() {
    ref.read(deviceRepositoryProvider).forgetAllPhones();
  }

  void powerOff() {
    ref.read(deviceRepositoryProvider).powerOff();
  }

  void openPairingMode() {
    ref.read(deviceRepositoryProvider).openPairingMode();
  }
}

final AutoDisposeNotifierProvider<DashboardViewController, DashboardState>
dashboardProvider =
    NotifierProvider.autoDispose<DashboardViewController, DashboardState>(
      DashboardViewController.new,
    );
