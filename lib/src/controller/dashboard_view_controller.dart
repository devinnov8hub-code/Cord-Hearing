import 'dart:async';

import 'package:cord_hearing/src/core/services/device_repository.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardState {
  DashboardState({
    this.batteryLevel = 0,
    this.connectionState = 'Disconnected',
    this.micMode = MicMode.omni,
    this.volume = 6,
    this.deviceName = 'Unknown Device',
  });
  final int batteryLevel;
  final String connectionState;
  final MicMode micMode;
  final int volume;
  final String deviceName;

  DashboardState copyWith({
    int? batteryLevel,
    String? connectionState,
    MicMode? micMode,
    int? volume,
    String? deviceName,
  }) {
    return DashboardState(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      connectionState: connectionState ?? this.connectionState,
      micMode: micMode ?? this.micMode,
      volume: volume ?? this.volume,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}

class DashboardViewController extends AutoDisposeNotifier<DashboardState> {
  StreamSubscription<int>? _batterySub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  @override
  DashboardState build() {
    final repo = ref.read(deviceRepositoryProvider);

    ref.onDispose(() {
      _batterySub?.cancel();
      _connectionSub?.cancel();
    });

    _batterySub = repo.batteryLevel.listen((level) {
      state = state.copyWith(batteryLevel: level);
    });

    _connectionSub = repo.connectionState.listen((status) {
      state = state.copyWith(
        connectionState:
            status.name[0].toUpperCase() + status.name.substring(1),
      );
    });

    final device = repo.connectedDevice;
    var name = ''; // Fallback to match mock
    if (device != null) {
      name = device.platformName.isNotEmpty
          ? device.platformName
          : device.remoteId.str;
    }

    // Request initial status
    repo.requestStatus();

    return DashboardState(deviceName: name);
  }

  void setVolume(int vol) {
    if (vol < 0 || vol > 10) return;
    state = state.copyWith(volume: vol);
    ref.read(deviceRepositoryProvider).setVolume(vol);
  }

  void setMicMode(MicMode mode) {
    state = state.copyWith(micMode: mode);
    ref.read(deviceRepositoryProvider).setMicMode(mode);
  }
}

final AutoDisposeNotifierProvider<DashboardViewController, DashboardState>
dashboardProvider =
    NotifierProvider.autoDispose<DashboardViewController, DashboardState>(() {
      return DashboardViewController();
    });
