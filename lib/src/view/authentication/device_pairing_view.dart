import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class DevicePairingView extends StatelessWidget {
  const DevicePairingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18).r,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                48.verticalSpace,
                Center(
                  child: SvgPicture.asset(
                    AppAssets.bluetoothScanning,
                    height: 220.h,
                  ),
                ),
                32.verticalSpace,
                Text(
                  'Make sure your hearing device is turned on and\nBluetooth is enabled on your phone. Keep your device\nclose to your phone while we search for and connect\nto it.',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 14.spMin,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                32.verticalSpace,
                Center(
                  child: SizedBox(
                    width: 200.w,
                    child: AppButton(
                      text: 'Scan',
                      onPressed: () {},
                    ),
                  ),
                ),
                48.verticalSpace,
                Text(
                  'Available Devices',
                  style: TextStyle(
                    fontSize: 18.spMin,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                16.verticalSpace,
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      const _DeviceListItem(name: 'AID-4435-5e'),
                      Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      const _DeviceListItem(name: 'AID-6721-9x'),
                      Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      const _DeviceListItem(name: 'AID-9813-4k'),
                    ],
                  ),
                ),
                48.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceListItem extends StatelessWidget {
  const _DeviceListItem({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20).r,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 16.spMin,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(
            height: 36.h,
            width: 100.w,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B5C7F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Connect',
                style: TextStyle(
                  fontSize: 14.spMin,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
