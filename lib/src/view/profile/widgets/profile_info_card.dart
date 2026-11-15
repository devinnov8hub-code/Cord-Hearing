import 'package:change_case/change_case.dart';
import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/services/paired_devices_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileInfoCard extends ConsumerWidget {
  const ProfileInfoCard({required this.deviceName, super.key});
  final String deviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    final email = (user?.email ?? '').trim();
    final rawDisplayName = (user?.displayName ?? '').trim();
    final displayName = rawDisplayName.isNotEmpty
        ? rawDisplayName
        : (email.isNotEmpty && email.contains('@')
              ? email.split('@').first
              : 'Account User');

    final dashboardState = ref.watch(dashboardProvider);
    final pairedDevices = ref.watch(pairedDevicesProvider);
    final resolvedDeviceLabel = dashboardState.isConnected
        ? deviceName
        : (pairedDevices.isNotEmpty
              ? '${pairedDevices.first.name} (Offline)'
              : 'No device paired');

    return Container(
      padding: const EdgeInsets.all(20).r,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 16.spMin,
              fontWeight: FontWeight.w600,
            ),
          ),
          24.verticalSpace,
          Center(
            child: CircleAvatar(
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              radius: 50.r,
              child: Icon(
                CupertinoIcons.person_alt_circle,
                size: 40.spMin,
                color: Colors.blueGrey,
              ),
            ),
          ),
          24.verticalSpace,
          _buildInfoField(
            icon: CupertinoIcons.person,
            value: displayName.toCapitalCase(),
          ),
          if (email.isNotEmpty) ...[
            16.verticalSpace,
            _buildInfoField(
              icon: CupertinoIcons.mail,
              value: email,
              textColor: Colors.grey[600],
            ),
          ],
          16.verticalSpace,
          _buildInfoField(
            icon: Icons.bluetooth,
            value: resolvedDeviceLabel,
            textColor: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String value,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14).r,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.black87,
            size: 20.spMin,
          ),
          12.horizontalSpace,
          Text(
            value,
            style: TextStyle(
              fontSize: 14.spMin,
              color: textColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
