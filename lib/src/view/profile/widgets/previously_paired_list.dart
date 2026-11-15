import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/bluetooth_device_service.dart';
import 'package:cord_hearing/src/core/services/paired_devices_service.dart';
import 'package:cord_hearing/src/core/services/toast_service.dart';
import 'package:cord_hearing/src/model/paired_device_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PreviouslyPairedList extends ConsumerWidget {
  const PreviouslyPairedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairedDevices = ref.watch(pairedDevicesProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final repo = ref.watch(deviceRepositoryProvider);
    final activeRemoteId = repo.connectedDevice?.remoteId.str.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Previously Paired on this account',
              style: TextStyle(
                fontSize: 16.spMin,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (pairedDevices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ).r,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${pairedDevices.length}',
                  style: TextStyle(
                    fontSize: 12.spMin,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
          ],
        ),
        16.verticalSpace,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).r,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: pairedDevices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20).r,
                  child: Column(
                    children: [
                      Icon(
                        Icons.hearing_disabled_outlined,
                        size: 28.spMin,
                        color: Colors.grey[400],
                      ),
                      8.verticalSpace,
                      Text(
                        'No devices paired on this account yet',
                        style: TextStyle(
                          fontSize: 14.spMin,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        'Hearing aids you pair while signed in will be saved here for quick reconnection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.spMin,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: List.generate(pairedDevices.length, (index) {
                    final record = pairedDevices[index];
                    final isCurrentlyConnected =
                        dashboardState.isConnected &&
                        activeRemoteId != null &&
                        activeRemoteId == record.remoteId.toLowerCase();

                    return Column(
                      children: [
                        _buildDeviceItem(
                          context,
                          ref,
                          record: record,
                          isCurrentlyConnected: isCurrentlyConnected,
                        ),
                        if (index < pairedDevices.length - 1)
                          Divider(
                            height: 1,
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceItem(
    BuildContext context,
    WidgetRef ref, {
    required PairedDeviceRecord record,
    required bool isCurrentlyConnected,
  }) {
    final subtitleParts = <String>[
      record.formatRelativeTime(),
      if (record.firmwareVersion.isNotEmpty) 'FW v${record.firmwareVersion}',
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: isCurrentlyConnected
          ? null
          : () => _connectToRecord(ref, record),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12).r,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8).r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrentlyConnected
                    ? AppColors.primaryColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                border: Border.all(
                  color: isCurrentlyConnected
                      ? AppColors.primaryColor
                      : Colors.grey,
                ),
              ),
              child: Icon(
                Icons.hearing,
                size: 20.spMin,
                color: isCurrentlyConnected
                    ? AppColors.primaryColor
                    : Colors.grey[700],
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          record.name,
                          style: TextStyle(
                            fontSize: 14.spMin,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentlyConnected) ...[
                        8.horizontalSpace,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ).r,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'Connected',
                            style: TextStyle(
                              fontSize: 10.spMin,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  4.verticalSpace,
                  Text(
                    subtitleParts.join(' • '),
                    style: TextStyle(
                      fontSize: 12.spMin,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                color: Colors.grey[600],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              onSelected: (value) async {
                if (value == 'connect') {
                  await _connectToRecord(ref, record);
                } else if (value == 'remove') {
                  await ref
                      .read(pairedDevicesProvider.notifier)
                      .removeDevice(record.remoteId);
                  Toasts.showSuccess(
                    'Removed ${record.name} from this account',
                  );
                }
              },
              itemBuilder: (context) => [
                if (!isCurrentlyConnected)
                  const PopupMenuItem<String>(
                    value: 'connect',
                    child: Row(
                      children: [
                        Icon(Icons.bluetooth_connected, size: 18),
                        SizedBox(width: 8),
                        Text('Connect'),
                      ],
                    ),
                  ),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Remove from account',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectToRecord(
    WidgetRef ref,
    PairedDeviceRecord record,
  ) async {
    final ok = await ref
        .read(dashboardProvider.notifier)
        .connectToPairedDevice(record);
    if (ok) {
      Toasts.showSuccess('Connected to ${record.name}');
    } else {
      Toasts.showError(
        'Could not connect to ${record.name}. Ensure it is powered on and nearby.',
      );
    }
  }
}
