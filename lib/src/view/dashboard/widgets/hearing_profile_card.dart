import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                profile: ChordProfile.normal,
                icon: AppAssets.earIcon,
                current: state.profile,
                onTap: () => controller.setProfile(ChordProfile.normal),
              ),
              8.horizontalSpace,
              _buildProfileButton(
                profile: ChordProfile.noisy,
                icon: AppAssets.waveformIcon,
                current: state.profile,
                onTap: () => controller.setProfile(ChordProfile.noisy),
              ),
              8.horizontalSpace,
              _buildProfileButton(
                profile: ChordProfile.music,
                icon: AppAssets.musicNoteIcon,
                current: state.profile,
                onTap: () => controller.setProfile(ChordProfile.music),
              ),
            ],
          ),
          12.verticalSpace,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8).r,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.spMin,
                  color: AppColors.primaryColor,
                ),
                8.horizontalSpace,
                Expanded(
                  child: Text(
                    state.profile.description,
                    style: TextStyle(
                      fontSize: 11.spMin,
                      color: Colors.grey[700],
                      height: 1.3,
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

  Widget _buildProfileButton({
    required ChordProfile profile,
    required String icon,
    required ChordProfile current,
    required VoidCallback onTap,
  }) {
    final isSelected = profile == current;
    const whiteColor = Color.fromRGBO(255, 255, 255, 1);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4).r,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : whiteColor,
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
              SvgPicture.asset(
                icon,
                colorFilter: ColorFilter.mode(
                  isSelected ? whiteColor : Colors.black87,
                  BlendMode.srcIn,
                ),
                width: 20.spMin,
              ),
              4.verticalSpace,
              Text(
                profile.label,
                style: TextStyle(
                  fontSize: 12.spMin,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              2.verticalSpace,
              Text(
                profile.subtitle,
                style: TextStyle(
                  fontSize: 10.spMin,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? whiteColor : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
