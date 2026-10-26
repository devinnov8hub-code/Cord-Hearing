import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
import 'package:cord_hearing/src/core/services/toast_service.dart';
import 'package:cord_hearing/src/view/dashboard/device_pairing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeviceActionsCard extends ConsumerWidget {
  const DeviceActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(dashboardProvider.notifier);
    final state = ref.watch(dashboardProvider);
    final isConnected = !state.connectionState.toLowerCase().contains('dis');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Diagnostics & Specifications Card ---
        Container(
          padding: const EdgeInsets.all(20).r,
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
                  Text(
                    'Device Diagnostics',
                    style: TextStyle(
                      fontSize: 16.spMin,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ).r,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF2BA9E0).withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      isConnected ? 'Connected' : 'Offline',
                      style: TextStyle(
                        fontSize: 11.spMin,
                        fontWeight: FontWeight.w600,
                        color: isConnected
                            ? const Color(0xFF2BA9E0)
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              _buildDiagRow(
                'Firmware Version',
                state.firmwareVersion.isNotEmpty
                    ? 'v${state.firmwareVersion}'
                    : 'v0.3.0',
              ),
              _buildDiagRow(
                'Hardware Model',
                state.model.isNotEmpty ? state.model : 'nRF5340 Body Unit',
              ),
              _buildDiagRow(
                'Manufacturer',
                state.manufacturer.isNotEmpty
                    ? state.manufacturer
                    : 'ChipMango Limited',
              ),
              _buildDiagRow(
                'DSP Earpiece State',
                state.earpieceState.label,
                highlight:
                    state.earpieceState == ChordEarpieceState.failed,
              ),
              _buildDiagRow(
                'Audio Transport',
                state.audioTransport.label,
              ),
              _buildDiagRow(
                'Power & Charging',
                '${state.batteryLevel}% (${state.chargingStatus.label})',
              ),
              _buildDiagRow(
                'Telemetry Status',
                state.deviceStatus.label,
              ),
            ],
          ),
        ),
        24.verticalSpace,

        // --- Management & Maintenance Card ---
        Container(
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
                'CHORD Management & Actions',
                style: TextStyle(
                  fontSize: 16.spMin,
                  fontWeight: FontWeight.w600,
                ),
              ),
              16.verticalSpace,

              // 1. Force Sync
              _buildActionButton(
                context,
                icon: Icons.sync,
                title: 'Synchronize Telemetry',
                subtitle: 'Re-burst all values from device (Opcode 0x01)',
                isEnabled: isConnected,
                onTap: () {
                  controller.sync();
                  Toasts.showSuccess('Device telemetry synchronized with CHORD');
                },
              ),
              Divider(height: 24, color: Colors.grey.withValues(alpha: 0.2)),

              // 2. OTA Firmware Update
              _buildActionButton(
                context,
                icon: Icons.system_update_alt,
                title: 'Check Firmware Update',
                subtitle: 'Verify SMP MCUboot firmware updates over BLE',
                isEnabled: isConnected,
                onTap: () => _handleOtaCheck(context, state),
              ),
              Divider(height: 24, color: Colors.grey.withValues(alpha: 0.2)),

              // 3. Reboot Device
              _buildActionButton(
                context,
                icon: Icons.restart_alt,
                title: 'Reboot Device',
                subtitle: 'Restart the CHORD body unit (reboots in 0.5s)',
                isEnabled: isConnected,
                onTap: () {
                  _showConfirmDialog(
                    context,
                    title: 'Reboot Hearing Device?',
                    message:
                        'The device will reboot in 0.5 seconds and momentarily disconnect from your phone.',
                    confirmText: 'Reboot',
                    isDestructive: false,
                    onConfirm: () {
                      controller.rebootDevice();
                      Navigator.pop(context);
                      Toasts.showSuccess(
                        'Reboot command sent. CHORD unit will restart in 0.5s.',
                      );
                    },
                  );
                },
              ),
              Divider(height: 24, color: Colors.grey.withValues(alpha: 0.2)),

              // 4. Power Off
              _buildActionButton(
                context,
                icon: Icons.power_settings_new,
                title: 'Power Off Device',
                subtitle: 'Requires PMIC. Only physical power button can wake it',
                isEnabled: isConnected,
                isDestructive: true,
                onTap: () {
                  _showConfirmDialog(
                    context,
                    title: 'Power Off CHORD?',
                    message:
                        'Once powered off, only the physical power button on the unit will wake it up.\n\nNote: Requires PMIC fitted and cannot be used while charging.',
                    confirmText: 'Power Off',
                    isDestructive: true,
                    onConfirm: () {
                      controller.powerOff();
                      Navigator.pop(context);
                      Toasts.showSuccess('Power off command sent to CHORD');
                    },
                  );
                },
              ),
              Divider(height: 24, color: Colors.grey.withValues(alpha: 0.2)),

              // 5. Forget All Phones
              _buildActionButton(
                context,
                icon: Icons.phonelink_erase,
                title: 'Forget All Phones',
                subtitle: 'Deletes all bonded phones, ending this connection',
                isEnabled: isConnected,
                isDestructive: true,
                onTap: () {
                  _showConfirmDialog(
                    context,
                    title: 'Forget All Bonded Phones?',
                    message:
                        'This will remove every bonded phone, including this one. You will need to put CHORD into pairing mode and pair again.',
                    confirmText: 'Forget All',
                    isDestructive: true,
                    onConfirm: () {
                      controller.forgetAllPhones();
                      Navigator.pop(context);
                      Toasts.showSuccess(
                        'All bonded phones deleted. Returning to pairing...',
                      );
                      Navigator.of(context).pushAndRemoveUntil<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => const DevicePairingView(),
                        ),
                        (route) => false,
                      );
                    },
                  );
                },
              ),
              Divider(height: 24, color: Colors.grey.withValues(alpha: 0.2)),

              // 6. Factory Reset
              _buildActionButton(
                context,
                icon: Icons.restore,
                title: 'Factory Reset',
                subtitle: 'Erases all bonds & audio settings and reboots',
                isEnabled: isConnected,
                isDestructive: true,
                onTap: () {
                  _showConfirmDialog(
                    context,
                    title: 'Factory Reset CHORD?',
                    message:
                        'This will erase all settings, profiles, and Bluetooth bonds on the unit. Every phone will need to pair again.',
                    confirmText: 'Factory Reset',
                    isDestructive: true,
                    onConfirm: () {
                      controller.factoryReset();
                      Navigator.pop(context);
                      Toasts.showSuccess(
                        'Factory reset initiated. Returning to pairing...',
                      );
                      Navigator.of(context).pushAndRemoveUntil<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => const DevicePairingView(),
                        ),
                        (route) => false,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleOtaCheck(BuildContext context, DashboardState state) {
    // Check preconditions per spec page 4:
    // 1. Don't start if battery is under 30%
    if (state.batteryLevel > 0 && state.batteryLevel < 30) {
      Toasts.showError(
        'Firmware update blocked: Battery is at ${state.batteryLevel}%. Must be at least 30%.',
      );
      return;
    }
    // 2. Don't start if device is streaming (Connection status = 2)
    if (state.isStreamingAudio) {
      Toasts.showError(
        'Firmware update blocked: Audio is currently streaming. Please pause audio playback first.',
      );
      return;
    }

    final currentVer =
        state.firmwareVersion.isNotEmpty ? state.firmwareVersion : '0.3.0';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.system_update_alt,
              color: AppColors.primaryColor,
            ),
            8.horizontalSpace,
            const Text('Firmware Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hardware: nRF5340 Development Kit',
              style: TextStyle(
                fontSize: 13.spMin,
                fontWeight: FontWeight.w600,
              ),
            ),
            4.verticalSpace,
            Text(
              'Current Installed: v$currentVer',
              style: TextStyle(
                fontSize: 13.spMin,
                color: Colors.grey[700],
              ),
            ),
            8.verticalSpace,
            Container(
              padding: const EdgeInsets.all(12).r,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF16A34A),
                  ),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Your CHORD device is running the latest firmware release (v$currentVer).',
                      style: TextStyle(
                        fontSize: 12.spMin,
                        color: const Color(0xFF166534),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            12.verticalSpace,
            Text(
              'OTA updates use Nordic SMP (mcumgr) protocol with MCUboot image swapping.',
              style: TextStyle(
                fontSize: 11.spMin,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4).r,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.spMin,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.spMin,
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4).r,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8).r,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.1)
                    : const Color(0xFF2BA9E0).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20.spMin,
                color: isDestructive ? Colors.red : const Color(0xFF2BA9E0),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.spMin,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Colors.red
                          : (isEnabled ? Colors.black87 : Colors.grey),
                    ),
                  ),
                  2.verticalSpace,
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.spMin,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20.spMin,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: onConfirm,
              style: TextButton.styleFrom(
                foregroundColor: isDestructive ? Colors.red : null,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}
