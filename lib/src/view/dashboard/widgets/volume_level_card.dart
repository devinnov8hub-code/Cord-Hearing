import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VolumeLevelCard extends ConsumerWidget {
  const VolumeLevelCard({super.key});

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
                Icons.volume_up,
                color: Colors.grey[700],
                size: 20.spMin,
              ),
              8.horizontalSpace,
              Text(
                'Volume level',
                style: TextStyle(
                  fontSize: 14.spMin,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => controller.setVolume(state.volume - 1),
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  radius: 20.r,
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ).r,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.volume.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.spMin,
                      ),
                    ),
                    16.horizontalSpace,
                    Row(
                      children: List.generate(10, (index) {
                        return Container(
                          width: 4.w,
                          height: 16.h,
                          margin: EdgeInsets.only(
                            right: index < 9 ? 4.w : 0,
                          ),
                          decoration: BoxDecoration(
                            color: index < state.volume
                                ? AppColors.primaryColor
                                : Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => controller.setVolume(state.volume + 1),
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  radius: 20.r,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
