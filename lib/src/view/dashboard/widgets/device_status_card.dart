import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/bluetooth_device_service.dart';
import 'package:cord_hearing/src/view/dashboard/device_pairing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DeviceStatusCard extends ConsumerWidget {
  const DeviceStatusCard({super.key});

  String _getBatteryAsset(int level, ChordChargingStatus chargingStatus) {
    if (chargingStatus == ChordChargingStatus.charging) {
      return AppAssets.batteryStatusCharging;
    }
    if (level <= 20) {
      return AppAssets.batteryStatusLow;
    }
    return AppAssets.batteryStatusIdle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final isConnected = state.isConnected;
    final isDisconnected = !isConnected;
    final cleanFw = state.firmwareVersion.trim();

    return Container(
      padding: const EdgeInsets.all(16).r,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.hearing,
                    color: Colors.grey[700],
                    size: 20.spMin,
                  ),
                  8.horizontalSpace,
                  Text(
                    state.deviceName,
                    style: TextStyle(
                      fontSize: 16.spMin,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (cleanFw.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ).r,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'FW v$cleanFw',
                    style: TextStyle(
                      fontSize: 11.spMin,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    _getBatteryAsset(state.batteryLevel, state.chargingStatus),
                    height: 24.h,
                  ),
                  8.horizontalSpace,
                  Text(
                    isConnected || state.batteryLevel > 0
                        ? '${state.batteryLevel}%'
                        : '—%',
                    style: TextStyle(
                      fontSize: 16.spMin,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isConnected &&
                      state.chargingStatus == ChordChargingStatus.charging) ...[
                    6.horizontalSpace,
                    Icon(
                      Icons.bolt,
                      color: Colors.amber[700],
                      size: 18.spMin,
                    ),
                  ],
                ],
              ),
              GestureDetector(
                onTap: isDisconnected
                    ? () async {
                        final ok = await ref
                            .read(dashboardProvider.notifier)
                            .reconnect();
                        if (!ok && context.mounted) {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (context) => const DevicePairingView(),
                            ),
                          );
                        }
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isDisconnected
                          ? Icons.bluetooth_disabled
                          : Icons.bluetooth_connected,
                      color: isDisconnected
                          ? Colors.red
                          : AppColors.primaryColor,
                      size: 20.spMin,
                    ),
                    4.horizontalSpace,
                    Text(
                      state.isStreamingAudio
                          ? 'Streaming Audio (${state.audioTransport.label})'
                          : (isConnected
                                ? 'Connected'
                                : 'Disconnected • Connect'),
                      style: TextStyle(
                        fontSize: 14.spMin,
                        color: isDisconnected
                            ? Colors.red
                            : AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Battery Warnings matching device light patterns (Spec Section 5 & 9)
          if (!isDisconnected &&
              state.chargingStatus != ChordChargingStatus.charging &&
              state.batteryLevel > 0 &&
              state.batteryLevel <= 15) ...[
            12.verticalSpace,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ).r,
              decoration: BoxDecoration(
                color: state.batteryLevel <= 10
                    ? Colors.red.withValues(alpha: 0.12)
                    : Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: state.batteryLevel <= 10
                      ? Colors.red
                      : Colors.amber[700]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.batteryLevel <= 10
                        ? Icons.battery_alert
                        : Icons.battery_charging_full,
                    color: state.batteryLevel <= 10
                        ? Colors.red
                        : Colors.amber[900],
                    size: 18.spMin,
                  ),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      state.batteryLevel <= 10
                          ? 'Battery Critical (${state.batteryLevel}%): Status light flashes red every 2s. Connect charger.'
                          : 'Battery Low (${state.batteryLevel}%): Status light flashes red every 5s.',
                      style: TextStyle(
                        fontSize: 12.spMin,
                        color: state.batteryLevel <= 10
                            ? Colors.red[900]
                            : Colors.amber[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Active Fault Code Alert (Spec Section 10: F01-F08)
          if (!isDisconnected && state.faultCode.hasFault) ...[
            12.verticalSpace,
            Container(
              padding: const EdgeInsets.all(12).r,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      8.horizontalSpace,
                      Text(
                        state.faultCode.screenLabel,
                        style: TextStyle(
                          fontSize: 13.spMin,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[900],
                        ),
                      ),
                    ],
                  ),
                  4.verticalSpace,
                  Text(
                    state.faultCode.meaning,
                    style: TextStyle(
                      fontSize: 12.spMin,
                      color: Colors.grey[800],
                    ),
                  ),
                  8.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Action: ${state.faultCode.action}',
                        style: TextStyle(
                          fontSize: 11.spMin,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (state.faultCode.canReboot)
                        SizedBox(
                          height: 28.h,
                          child: ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(dashboardProvider.notifier)
                                  .rebootDevice();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ).r,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                            child: Text(
                              'Reboot Chord',
                              style: TextStyle(
                                fontSize: 11.spMin,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (!isDisconnected &&
              state.earpieceState == ChordEarpieceState.failed) ...[
            12.verticalSpace,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ).r,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.amber[700]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber[900],
                    size: 18.spMin,
                  ),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Earpiece unplugged or not detected. Check cable connection.',
                      style: TextStyle(
                        fontSize: 12.spMin,
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
