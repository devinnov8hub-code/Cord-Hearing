import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/services/device_repository.dart';
import 'package:cord_hearing/src/core/widgets/dialog_sheet.dart';
import 'package:cord_hearing/src/view/dashboard/widgets/dashboard_header.dart';
import 'package:cord_hearing/src/view/dashboard/widgets/device_status_card.dart';
import 'package:cord_hearing/src/view/dashboard/widgets/disconnected_bottom_sheet.dart';
import 'package:cord_hearing/src/view/dashboard/widgets/microphone_mode_card.dart';
import 'package:cord_hearing/src/view/dashboard/widgets/volume_level_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<DashboardState>(dashboardProvider, (previous, next) {
      if (previous != null &&
          !previous.connectionState.toLowerCase().contains('dis') &&
          next.connectionState.toLowerCase().contains('dis')) {
        DialogSheet.showCustom(
          context,
          child: DisconnectedBottomSheet(
            deviceName: next.deviceName,
            onGoToPairing: () {
              Navigator.of(context).pop(); // Close bottom sheet
              Navigator.of(context).pop(); // Go back to pairing view
            },
            onRetry: () {
              Navigator.of(context).pop(); // Close bottom sheet
              // Retry connection
              final repo = ref.read(deviceRepositoryProvider);
              if (repo.connectedDevice != null) {
                repo.connect(repo.connectedDevice!);
              }
            },
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 5).r,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardHeader(),
              16.verticalSpace,
              Center(
                child: Image.asset(
                  AppAssets.hearingAid,
                  height: 268.h,
                  fit: BoxFit.contain,
                ),
              ),
              16.verticalSpace,
              const DeviceStatusCard(),
              16.verticalSpace,
              const MicrophoneModeCard(),
              16.verticalSpace,
              const VolumeLevelCard(),
              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
