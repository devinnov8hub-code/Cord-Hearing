import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
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
    final isDisconnected =
        state.connectionState.toLowerCase().contains('dis');

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
              if (state.firmwareVersion.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3).r,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'FW v${state.firmwareVersion}',
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
                    '${state.batteryLevel}%',
                    style: TextStyle(
                      fontSize: 16.spMin,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (state.chargingStatus == ChordChargingStatus.charging) ...[
                    6.horizontalSpace,
                    Icon(
                      Icons.bolt,
                      color: Colors.amber[700],
                      size: 18.spMin,
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.bluetooth,
                    color: isDisconnected
                        ? Colors.red
                        : AppColors.primaryColor,
                    size: 20.spMin,
                  ),
                  4.horizontalSpace,
                  Text(
                    state.isStreamingAudio
                        ? 'Streaming Audio (${state.audioTransport.label})'
                        : state.connectionState,
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
            ],
          ),
          // Earpiece status warning alert (Doc: earpiece state 4 = failed/unplugged)
          if (!isDisconnected &&
              state.earpieceState == ChordEarpieceState.failed) ...[
            12.verticalSpace,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8).r,
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
                      'Earpiece unplugged or not detected.',
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
