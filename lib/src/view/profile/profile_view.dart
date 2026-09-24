import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/services/device_repository.dart';
import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:cord_hearing/src/core/widgets/dialog_sheet.dart';
import 'package:cord_hearing/src/view/profile/widgets/disconnect_bottom_sheet.dart';
import 'package:cord_hearing/src/view/profile/widgets/previously_paired_list.dart';
import 'package:cord_hearing/src/view/profile/widgets/profile_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

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
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
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
              32.verticalSpace,
              const PreviouslyPairedList(),
              32.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
