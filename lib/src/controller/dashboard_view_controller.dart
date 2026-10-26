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
    this.chargingStatus = ChordChargingStatus.discharging,
    this.audioTransport = ChordAudioTransport.none,
    this.deviceStatus = ChordDeviceStatus.ok,
    this.deviceName = 'Unknown Device',
    this.firmwareVersion = '',
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
  final ChordChargingStatus chargingStatus;
  final ChordAudioTransport audioTransport;
  final ChordDeviceStatus deviceStatus;
  final String deviceName;
  final String firmwareVersion;
  final String manufacturer;
  final String model;
  final bool isStreamingAudio;
  final String? lastCommandMessage;

  DashboardState copyWith({
    int? batteryLevel,
    String? connectionState,
    int? volume,
    bool? isMuted,
    ChordMicMode? micMode,
    ChordProfile? profile,
    ChordEarpieceState? earpieceState,
    ChordChargingStatus? chargingStatus,
    ChordAudioTransport? audioTransport,
    ChordDeviceStatus? deviceStatus,
    String? deviceName,
    String? firmwareVersion,
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
      chargingStatus: chargingStatus ?? this.chargingStatus,
      audioTransport: audioTransport ?? this.audioTransport,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      deviceName: deviceName ?? this.deviceName,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
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
        state = state.copyWith(batteryLevel: level);
      }),
      repo.connectionState.listen((status) {
        state = state.copyWith(
          connectionState:
              status.name[0].toUpperCase() + status.name.substring(1),
        );
      }),
      repo.volume.listen((vol) {
        state = state.copyWith(volume: vol);
      }),
      repo.isMuted.listen((muted) {
        state = state.copyWith(isMuted: muted);
      }),
      repo.activeProfile.listen((p) {
        state = state.copyWith(profile: p);
      }),
      repo.micMode.listen((mode) {
        state = state.copyWith(micMode: mode);
      }),
      repo.chargingStatus.listen((status) {
        state = state.copyWith(chargingStatus: status);
      }),
      repo.deviceStatus.listen((status) {
        state = state.copyWith(deviceStatus: status);
      }),
      repo.earpieceState.listen((earpiece) {
        state = state.copyWith(earpieceState: earpiece);
      }),
      repo.audioTransport.listen((transport) {
        state = state.copyWith(audioTransport: transport);
      }),
      repo.connectionTelemetry.listen((telemetry) {
        state = state.copyWith(
          isStreamingAudio:
              telemetry == ChordConnectionTelemetry.streamingAudio,
        );
      }),
      repo.firmwareVersion.listen((version) {
        state = state.copyWith(firmwareVersion: version);
      }),
      repo.manufacturerName.listen((mfg) {
        state = state.copyWith(manufacturer: mfg);
      }),
      repo.modelNumber.listen((model) {
        state = state.copyWith(model: model);
      }),
      repo.controlResponses.listen((entry) {
        state = state.copyWith(
          lastCommandMessage:
              'Command 0x${entry.key.toRadixString(16)}: ${entry.value.description}',
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

    // Initialize with cached repo values
    final initial = DashboardState(
      deviceName: name,
      volume: repo.currentVolume,
      isMuted: repo.currentIsMuted,
      profile: repo.currentProfile,
      micMode: repo.currentMicMode,
      earpieceState: repo.currentEarpieceState,
      chargingStatus: repo.currentChargingStatus,
      audioTransport: repo.currentAudioTransport,
      firmwareVersion: repo.currentFirmwareVersion,
    );

    // Trigger full sync
    repo.sync();

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
}

final AutoDisposeNotifierProvider<DashboardViewController, DashboardState>
dashboardProvider =
    NotifierProvider.autoDispose<DashboardViewController, DashboardState>(
      DashboardViewController.new,
    );
