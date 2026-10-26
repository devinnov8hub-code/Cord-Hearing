import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
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
            padding: const EdgeInsets.all(4).r,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                _buildModeOption(
                  label: 'Omni',
                  icon: Icons.mic_none,
                  isSelected: state.micMode == ChordMicMode.omni,
                  onTap: () => controller.setMicMode(ChordMicMode.omni),
                ),
                _buildModeOption(
                  label: 'Directional',
                  icon: Icons.mic,
                  isSelected: state.micMode == ChordMicMode.directional,
                  onTap: () => controller.setMicMode(ChordMicMode.directional),
                ),
                _buildModeOption(
                  label: 'Bypass',
                  icon: Icons.hearing,
                  isSelected: state.micMode == ChordMicMode.bypass,
                  onTap: () => controller.setMicMode(ChordMicMode.bypass),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12).r,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black87,
                size: 22.spMin,
              ),
              6.verticalSpace,
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12.spMin,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
