import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DeviceStatusCard extends ConsumerWidget {
  const DeviceStatusCard({super.key});

  String _getBatteryAsset(int level) {
    if (level <= 20) {
      return AppAssets.batteryStatusLow;
    }
    // TODO(cord): Determine charging state when backend supports it
    return AppAssets.batteryStatusIdle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

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
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    _getBatteryAsset(state.batteryLevel),
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
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.bluetooth,
                    color: state.connectionState.toLowerCase().contains('dis')
                        ? Colors.red
                        : AppColors.primaryColor,
                    size: 20.spMin,
                  ),
                  4.horizontalSpace,
                  Text(
                    state.connectionState,
                    style: TextStyle(
                      fontSize: 16.spMin,
                      color: state.connectionState.toLowerCase().contains('dis')
                          ? Colors.red
                          : AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
