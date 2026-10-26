import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HearingProfileCard extends ConsumerWidget {
  const HearingProfileCard({super.key});

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: Colors.grey[700],
                    size: 20.spMin,
                  ),
                  8.horizontalSpace,
                  Text(
                    'Sound Profile',
                    style: TextStyle(
                      fontSize: 14.spMin,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                'Synced with OS presets',
                style: TextStyle(
                  fontSize: 11.spMin,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Row(
            children: [
              _buildProfileButton(
                label: 'Normal',
                icon: Icons.nature_people,
                profile: ChordProfile.normal,
                current: state.profile,
                onTap: () => controller.setProfile(ChordProfile.normal),
              ),
              8.horizontalSpace,
              _buildProfileButton(
                label: 'Noisy',
                icon: Icons.restaurant,
                profile: ChordProfile.noisy,
                current: state.profile,
                onTap: () => controller.setProfile(ChordProfile.noisy),
              ),
              8.horizontalSpace,
              _buildProfileButton(
                label: 'Music',
                icon: Icons.music_note,
                profile: ChordProfile.music,
                current: state.profile,
                onTap: () => controller.setProfile(ChordProfile.music),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton({
    required String label,
    required IconData icon,
    required ChordProfile profile,
    required ChordProfile current,
    required VoidCallback onTap,
  }) {
    final isSelected = profile == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12).r,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : Colors.grey.withValues(alpha: 0.3),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black87,
                size: 20.spMin,
              ),
              6.verticalSpace,
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.spMin,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
