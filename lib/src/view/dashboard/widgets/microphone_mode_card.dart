import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/device_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MicrophoneModeCard extends ConsumerWidget {
  const MicrophoneModeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final controller = ref.read(dashboardProvider.notifier);

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
                Icons.mic,
                color: Colors.grey[700],
                size: 20.spMin,
              ),
              8.horizontalSpace,
              Text(
                'Microphone mode',
                style: TextStyle(
                  fontSize: 14.spMin,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setMicMode(MicMode.omni),
                    child: Container(
                      decoration: BoxDecoration(
                        color: state.micMode == MicMode.omni
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic_none,
                            color: state.micMode == MicMode.omni
                                ? Colors.white
                                : Colors.white70,
                            size: 28.spMin,
                          ),
                          8.verticalSpace,
                          Text(
                            'Omnidirectional',
                            style: TextStyle(
                              color: state.micMode == MicMode.omni
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 12.spMin,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setMicMode(MicMode.directional),
                    child: Container(
                      decoration: BoxDecoration(
                        color: state.micMode == MicMode.directional
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic,
                            color: state.micMode == MicMode.directional
                                ? Colors.white
                                : Colors.white70,
                            size: 28.spMin,
                          ),
                          8.verticalSpace,
                          Text(
                            'Unidirectional',
                            style: TextStyle(
                              color: state.micMode == MicMode.directional
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 12.spMin,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
