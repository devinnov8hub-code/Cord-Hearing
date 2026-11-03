import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LogoutBottomSheet extends StatelessWidget {
  const LogoutBottomSheet({
    required this.onCancel,
    required this.onLogout,
    super.key,
  });

  final VoidCallback onCancel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).r,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Log Out',
            style: TextStyle(
              fontSize: 18.spMin,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          16.verticalSpace,
          Text(
            'Are you sure you want to log out of your Cord account? Any active connection to your hearing device will be disconnected.',
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
                  text: 'Log Out',
                  bgColor: const Color(0xFFD32F2F),
                  textColor: Colors.white,
                  onPressed: onLogout,
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

