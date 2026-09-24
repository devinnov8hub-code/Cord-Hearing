import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisconnectBottomSheet extends StatelessWidget {
  const DisconnectBottomSheet({
    required this.deviceName,
    required this.onCancel,
    required this.onDisconnect,
    super.key,
  });

  final String deviceName;
  final VoidCallback onCancel;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).r,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              text: 'Disconnect ',
              style: TextStyle(
                fontSize: 18.spMin,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: deviceName,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          16.verticalSpace,
          Text(
            'Disconnecting will stop communication between the app and your hearing device. You can reconnect the device again at any time.',
            style: TextStyle(
              fontSize: 14.spMin,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          32.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  bgColor: Colors.grey[300],
                  textColor: Colors.black,
                  onPressed: onCancel,
                  borderRadius: 24.r,
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: AppButton(
                  text: 'Disconnect',
                  bgColor: const Color(0xFFD32F2F),
                  textColor: Colors.white,
                  onPressed: onDisconnect,
                  borderRadius: 24.r,
                ),
              ),
            ],
          ),
          16.verticalSpace,
        ],
      ),
    );
  }
}
