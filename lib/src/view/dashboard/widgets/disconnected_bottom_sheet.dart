import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisconnectedBottomSheet extends StatelessWidget {
  const DisconnectedBottomSheet({
    required this.deviceName,
    required this.onGoToPairing,
    required this.onRetry,
    super.key,
  });
  final String deviceName;
  final VoidCallback onGoToPairing;
  final VoidCallback onRetry;

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
              text: 'Unable to connect to ',
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
            "We couldn't establish a connection with your hearing device. Make sure the device is turned on, nearby, and Bluetooth is enabled, then try again.",
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
                  text: 'Go to pairing',
                  bgColor: Colors.grey[300],
                  textColor: Colors.black,
                  onPressed: onGoToPairing,
                  borderRadius: 24.r,
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: AppButton(
                  text: 'Retry',
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  textColor: Colors.white,
                  onPressed: onRetry,
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
