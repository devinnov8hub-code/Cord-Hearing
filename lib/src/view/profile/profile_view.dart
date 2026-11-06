import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/bluetooth_device_service.dart';
import 'package:cord_hearing/src/core/services/firebase_auth_service.dart';
import 'package:cord_hearing/src/core/services/toast_service.dart';
import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:cord_hearing/src/core/widgets/dialog_sheet.dart';
import 'package:cord_hearing/src/view/authentication/login_view.dart';
import 'package:cord_hearing/src/view/help/chord_help_view.dart';
import 'package:cord_hearing/src/view/profile/widgets/device_actions_card.dart';
import 'package:cord_hearing/src/view/profile/widgets/disconnect_bottom_sheet.dart';
import 'package:cord_hearing/src/view/profile/widgets/logout_bottom_sheet.dart';
import 'package:cord_hearing/src/view/profile/widgets/previously_paired_list.dart';
import 'package:cord_hearing/src/view/profile/widgets/profile_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  void _showLogoutSheet(BuildContext context, WidgetRef ref) {
    final repo = ref.read(deviceRepositoryProvider);
    final authService = ref.read(authServiceProvider);

    DialogSheet.showCustom(
      context,
      child: LogoutBottomSheet(
        onCancel: () => Navigator.of(context).pop(),
        onLogout: () async {
          Navigator.of(context).pop(); // Close bottom sheet
          await repo.disconnect();
          await authService.signOut();
          Toasts.showSuccess('Logged out successfully');
          if (context.mounted) {
            await Navigator.of(context).pushAndRemoveUntil<void>(
              MaterialPageRoute<void>(
                builder: (context) => const LoginView(),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final repo = ref.read(deviceRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16).r,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.black,
              ),
            ),
          ),
        ),
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: const [
          // IconButton(
          //   onPressed: () => _showLogoutSheet(context, ref),
          //   tooltip: 'Log Out',
          //   icon: const Icon(
          //     Icons.logout_rounded,
          //     color: Color(0xFFD32F2F),
          //   ),
          // ),
          // 8.horizontalSpace,
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20).r,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileInfoCard(deviceName: state.deviceName),
              24.verticalSpace,
              AppButton(
                text: 'Disconnect device',
                icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
                bgColor: const Color(0xFFD32F2F),
                textColor: Colors.white,
                borderRadius: 24.r,
                onPressed: () {
                  DialogSheet.showCustom(
                    context,
                    child: DisconnectBottomSheet(
                      deviceName: state.deviceName,
                      onCancel: () => Navigator.of(context).pop(),
                      onDisconnect: () {
                        repo.disconnect();
                        Navigator.of(context).pop(); // Close bottom sheet
                        Navigator.of(context).pop(); // Go back to dashboard
                      },
                    ),
                  );
                },
              ),

              24.verticalSpace,
              const DeviceActionsCard(),

              24.verticalSpace,
              // CHORD Device Help & Guides Card (Spec Section 3, 5, 8, 12)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16).r,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFB9DCF7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          color: AppColors.primaryColor,
                          size: 20.spMin,
                        ),
                        8.horizontalSpace,
                        Text(
                          'Device Help & Guides',
                          style: TextStyle(
                            fontSize: 15.spMin,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    6.verticalSpace,
                    Text(
                      'Explore body unit button gestures, status light color patterns, and how to perform a hearing test on the device.',
                      style: TextStyle(
                        fontSize: 12.spMin,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    12.verticalSpace,
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const ChordHelpView(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                        child: Text(
                          'View Help & Guides',
                          style: TextStyle(
                            fontSize: 13.spMin,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              32.verticalSpace,
              const PreviouslyPairedList(),
              32.verticalSpace,
              AppButton(
                text: 'Log Out',
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFD32F2F),
                ),
                isOutlined: true,
                outlineColor: const Color(0xFFD32F2F),
                bgColor: Colors.white,
                textColor: const Color(0xFFD32F2F),
                borderRadius: 24.r,
                onPressed: () => _showLogoutSheet(context, ref),
              ),
              32.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
