import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/services/bluetooth_device_service.dart';
import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
import 'package:cord_hearing/src/core/services/chord_ota_service.dart';
import 'package:cord_hearing/src/core/services/toast_service.dart';
import 'package:cord_hearing/src/view/dashboard/device_pairing_view.dart';
import 'package:cord_hearing/src/view/profile/widgets/ota_update_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeviceActionsCard extends ConsumerStatefulWidget {
  const DeviceActionsCard({super.key});

  @override
  ConsumerState<DeviceActionsCard> createState() => _DeviceActionsCardState();
}

class _DeviceActionsCardState extends ConsumerState<DeviceActionsCard> {
  int _fwTapCount = 0;
  DateTime? _lastFwTap;

  void _onFirmwareRowTap() {
    final now = DateTime.now();
    if (_lastFwTap == null ||
        now.difference(_lastFwTap!) > const Duration(seconds: 3)) {
      _fwTapCount = 1;
    } else {
      _fwTapCount++;
    }
    _lastFwTap = now;

    if (_fwTapCount >= 5) {
      _fwTapCount = 0;
      final current = ref.read(developerOtaUnlockedProvider);
      ref.read(developerOtaUnlockedProvider.notifier).state = !current;
      Toasts.showSuccess(
        !current
            ? 'Developer firmware file installer enabled'
            : 'Developer firmware file installer hidden',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(dashboardProvider.notifier);
    final state = ref.watch(dashboardProvider);
    final isConnected = state.isConnected;
    final cleanFw = state.firmwareVersion.trim();
    final cleanModel = state.model.trim();
    final cleanHwRev = state.hardwareRevision.trim();
    final cleanMfg = state.manufacturer.trim();

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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onFirmwareRowTap,
                child: _buildDiagRow(
                  'Firmware Version',
                  cleanFw.isNotEmpty ? 'v$cleanFw' : '—',
                ),
              ),
              _buildDiagRow(
                'Hardware Model',
                cleanModel.isNotEmpty ? cleanModel : '—',
              ),
              _buildDiagRow(
                'Hardware Revision',
                cleanHwRev.isNotEmpty ? cleanHwRev : '—',
              ),
              _buildDiagRow(
                'Manufacturer',
                cleanMfg.isNotEmpty ? cleanMfg : '—',
              ),
              _buildDiagRow(
                'DSP Earpiece State',
                isConnected ? state.earpieceState.label : '—',
                highlight:
                    isConnected &&
                    state.earpieceState == ChordEarpieceState.failed,
              ),
              _buildDiagRow(
                'Active Fault Code',
                isConnected
                    ? (state.faultCode.hasFault
                          ? state.faultCode.screenLabel
                          : 'None (OK)')
                    : '—',
                highlight: isConnected && state.faultCode.hasFault,
              ),
              _buildDiagRow(
                'Audio Transport',
                isConnected ? state.audioTransport.label : '—',
              ),
              _buildDiagRow(
                'Power & Charging',
                isConnected
                    ? '${state.batteryLevel}% (${state.chargingStatus.label})'
                    : '—',
              ),
              _buildDiagRow(
                'Telemetry Status',
                isConnected ? state.deviceStatus.label : '—',
              ),
              _buildDiagRow(
                'App Build Version',
                'v${ChordBleConstants.appVersion}',
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
                  Toasts.showSuccess(
                    'Device telemetry synchronized with CHORD',
                  );
                },
              ),
              Divider(height: 24, color: Colors.grey.withValues(alpha: 0.2)),

              // 2. Add a Phone (Pair Another Phone) - Opcode 0x03
              _buildActionButton(
                context,
                icon: Icons.phonelink_ring,
                title: 'Add a Phone (Pair Another Phone)',
                subtitle:
                    'Opens 120s pairing mode on CHORD; this phone disconnects',
                isEnabled: isConnected,
                onTap: () {
                  _showConfirmDialog(
                    context,
                    title: 'Pair Another Phone?',
                    message:
                        'Opening pairing mode (Opcode 0x03) will disconnect this phone from CHORD so another phone can connect and pair.\n\nPairing mode will stay open on CHORD for 120 seconds.',
                    confirmText: 'Open Pairing Mode',
                    isDestructive: false,
                    onConfirm: () {
                      controller.openPairingMode();
                      Navigator.pop(context);
                      Toasts.showSuccess(
                        'Pairing mode opened on CHORD (120s countdown).',
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

              // 3. OTA Firmware Update
              _buildActionButton(
                context,
                icon: Icons.system_update_alt,
                title: 'Check Firmware Update',
                subtitle: 'Verify or install SMP MCUboot firmware over BLE',
                isEnabled: isConnected,
                onTap: () => _handleOtaCheck(context),
              ),
              Divider(height: 24, color: Colors.grey.withValues(alpha: 0.2)),

              // 4. Reboot Chord (Opcode 0x09)
              _buildActionButton(
                context,
                icon: Icons.restart_alt,
                title: 'Reboot Chord',
                subtitle:
                    'Restart the whole CHORD unit (reboots in 0.5s; reconnects in ~10s)',
                isEnabled: isConnected,
                onTap: () {
                  _showConfirmDialog(
                    context,
                    title: 'Reboot Chord?',
                    message:
                        'The device will restart the whole unit in 0.5 seconds and momentarily disconnect from your phone.',
                    confirmText: 'Reboot Chord',
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

              // 5. Shut Down (Opcode 0x08)
              _buildActionButton(
                context,
                icon: Icons.power_settings_new,
                title: 'Shut Down',
                subtitle:
                    'Powers off unit. Unplug charger first; power button wakes it',
                isEnabled: isConnected,
                isDestructive: true,
                onTap: () {
                  if (state.chargingStatus == ChordChargingStatus.charging) {
                    Toasts.showError(
                      'Shut down unavailable while charging. Please unplug the USB-C charger first.',
                    );
                    return;
                  }
                  _showConfirmDialog(
                    context,
                    title: 'Shut Down CHORD?',
                    message:
                        'Once powered off, only the physical power button on the unit or plugging in the charger will wake it up.\n\nNote: Requires PMIC fitted and cannot be used while charging.',
                    confirmText: 'Shut Down',
                    isDestructive: true,
                    onConfirm: () {
                      controller.powerOff();
                      Navigator.pop(context);
                      Toasts.showSuccess('Shut down command sent to CHORD');
                    },
                  );
                },
              ),
              Divider(height: 24, color: Colors.grey.withValues(alpha: 0.2)),

              // 6. Forget All Phones (Opcode 0x0a)
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

              // 7. Factory Reset (Opcode 0x02)
              _buildActionButton(
                context,
                icon: Icons.restore,
                title: 'Factory Reset',
                subtitle:
                    'App only: Erases all bonds, settings & profiles, and reboots',
                isEnabled: isConnected,
                isDestructive: true,
                onTap: () {
                  _showConfirmDialog(
                    context,
                    title: 'Factory Reset CHORD?',
                    message:
                        'Factory reset is only available from the CHORD app.\n\nThis will permanently erase all settings, hearing profiles, and Bluetooth bonds on the unit. Every phone will need to pair again.',
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

  void _handleOtaCheck(BuildContext context) {
    ref.read(chordOtaProvider.notifier).resetState();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => const OtaUpdateSheet(),
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
              fontSize: 12.spMin,
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
    // When disabled (offline), both regular and destructive buttons are greyed out
    final activeColor = !isEnabled
        ? Colors.grey
        : (isDestructive ? Colors.red : const Color(0xFF2BA9E0));
    final titleColor = !isEnabled
        ? Colors.grey[600]!
        : (isDestructive ? Colors.red : Colors.black87);

    return InkWell(
      onTap: () {
        if (!isEnabled) {
          Toasts.showError(
            'CHORD device is offline. Connect your device first.',
          );
          return;
        }
        onTap();
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4).r,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8).r,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20.spMin,
                  color: activeColor,
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
                        color: titleColor,
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
