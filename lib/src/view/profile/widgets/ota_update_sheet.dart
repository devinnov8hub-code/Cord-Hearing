import 'package:cord_hearing/src/controller/dashboard_view_controller.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/services/chord_ota_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtaUpdateSheet extends ConsumerWidget {
  const OtaUpdateSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(dashboardProvider);
    final otaState = ref.watch(chordOtaProvider);
    final otaController = ref.read(chordOtaProvider.notifier);
    final devUnlocked = ref.watch(developerOtaUnlockedProvider);

    final runningVer = dashState.firmwareVersion.trim().isNotEmpty
        ? 'v${dashState.firmwareVersion.trim()}'
        : '—';
    final hwRev = dashState.hardwareRevision.trim().isNotEmpty
        ? dashState.hardwareRevision.trim()
        : '—';

    final batteryOk =
        dashState.batteryLevel == 0 || dashState.batteryLevel >= 30;
    final streamingOk = !dashState.isStreamingAudio;

    return PopScope(
      canPop: !otaState.isBusy,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.r,
          right: 20.r,
          top: 20.r,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.r,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.system_update_alt,
                        color: AppColors.primaryColor,
                      ),
                      8.horizontalSpace,
                      Text(
                        'CHORD Firmware Update',
                        style: TextStyle(
                          fontSize: 17.spMin,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (!otaState.isBusy)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                ],
              ),
              12.verticalSpace,

              // Device & Hardware Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14).r,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    _buildMetaRow('Running Version (9e32000e)', runningVer),
                    6.verticalSpace,
                    _buildMetaRow('Hardware Revision (0x2A27)', hwRev),
                    6.verticalSpace,
                    _buildMetaRow(
                      'Battery Pre-Check (≥ 30%)',
                      dashState.batteryLevel > 0
                          ? '${dashState.batteryLevel}% (${batteryOk ? "OK" : "Too Low"})'
                          : '—',
                      valueColor: batteryOk ? const Color(0xFF16A34A) : Colors.red,
                    ),
                    6.verticalSpace,
                    _buildMetaRow(
                      'Audio Stream State',
                      streamingOk ? 'Idle (Ready)' : 'Streaming (Pause first)',
                      valueColor:
                          streamingOk ? const Color(0xFF16A34A) : Colors.red,
                    ),
                  ],
                ),
              ),
              14.verticalSpace,

              // Cloud status banner (when idle)
              if (otaState.phase == OtaPhase.idle) ...[
                Container(
                  padding: const EdgeInsets.all(12).r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10.r),
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
                          'Device is up to date on $runningVer ($hwRev).',
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
              ],

              // Selected Image Comparison Card
              if (otaState.selectedImage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14).r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFB9DCF7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected MCUboot Image (Slot 1 / Image 0)',
                        style: TextStyle(
                          fontSize: 13.spMin,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      8.verticalSpace,
                      _buildMetaRow(
                        'File',
                        otaState.selectedImage!.fileName,
                      ),
                      4.verticalSpace,
                      _buildMetaRow(
                        'Version Transition',
                        '$runningVer  →  v${otaState.selectedImage!.version}',
                        valueColor: AppColors.primaryColor,
                      ),
                      4.verticalSpace,
                      _buildMetaRow(
                        'Binary Size',
                        '${(otaState.selectedImage!.bytes.length / 1024).toStringAsFixed(1)} KB',
                      ),
                      4.verticalSpace,
                      _buildMetaRow(
                        'SHA-256',
                        '${otaState.selectedImage!.sha256Hex.substring(0, 16)}…',
                      ),
                      4.verticalSpace,
                      _buildMetaRow(
                        'Upload Mode',
                        'Test-Only (Firmware self-confirms)',
                      ),
                    ],
                  ),
                ),
                14.verticalSpace,
              ],

              // Active Progress Section (Uploading / Marking / Resetting / Swapping / Reconnecting)
              if (otaState.isBusy) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16).r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                          10.horizontalSpace,
                          Expanded(
                            child: Text(
                              _phaseTitle(otaState.phase),
                              style: TextStyle(
                                fontSize: 14.spMin,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      12.verticalSpace,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: LinearProgressIndicator(
                          minHeight: 8.h,
                          value: otaState.phase == OtaPhase.uploading
                              ? (otaState.uploadProgress / 100.0)
                              : (otaState.phase ==
                                            OtaPhase.swappingAndRebooting ||
                                        otaState.phase == OtaPhase.reconnecting
                                    ? (otaState.swapSecondsElapsed / 90.0)
                                          .clamp(0.0, 1.0)
                                    : null),
                          backgroundColor: Colors.grey[200],
                          color: AppColors.primaryColor,
                        ),
                      ),
                      8.verticalSpace,
                      Text(
                        otaState.statusMessage,
                        style: TextStyle(
                          fontSize: 12.spMin,
                          color: Colors.grey[800],
                          height: 1.35,
                        ),
                      ),
                      if (otaState.phase == OtaPhase.swappingAndRebooting ||
                          otaState.phase == OtaPhase.reconnecting) ...[
                        6.verticalSpace,
                        Text(
                          'MCUboot swaps images on reboot (typically 45–60s). Do not power off the unit.',
                          style: TextStyle(
                            fontSize: 11.spMin,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                14.verticalSpace,
              ],

              // Success Banner
              if (otaState.phase == OtaPhase.succeeded) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14).r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF16A34A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF16A34A),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Firmware Update Succeeded',
                              style: TextStyle(
                                fontSize: 14.spMin,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                            ),
                            4.verticalSpace,
                            Text(
                              otaState.statusMessage,
                              style: TextStyle(
                                fontSize: 12.spMin,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                14.verticalSpace,
              ],

              // Rollback Banner
              if (otaState.phase == OtaPhase.rolledBack) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14).r,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.amber[800]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.restore,
                        color: Colors.amber[900],
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Firmware Rolled Back by MCUboot',
                              style: TextStyle(
                                fontSize: 14.spMin,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber[900],
                              ),
                            ),
                            4.verticalSpace,
                            Text(
                              otaState.statusMessage,
                              style: TextStyle(
                                fontSize: 12.spMin,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                14.verticalSpace,
              ],

              // Error / Refusal Banner
              if (otaState.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14).r,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: Text(
                          otaState.errorMessage!,
                          style: TextStyle(
                            fontSize: 12.spMin,
                            color: Colors.red[900],
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                14.verticalSpace,
              ],

              // Developer-Only "Install from file" Section (Section 8)
              if (devUnlocked && !otaState.isBusy) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14).r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.developer_mode,
                            size: 18.spMin,
                            color: AppColors.primaryColor,
                          ),
                          6.horizontalSpace,
                          Text(
                            'Developer OTA — Install from File',
                            style: TextStyle(
                              fontSize: 13.spMin,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      6.verticalSpace,
                      Text(
                        'Select a signed MCUboot .bin file for image 0 (application core). Never upload dfu_application.zip directly — unpack it first.',
                        style: TextStyle(
                          fontSize: 11.spMin,
                          color: Colors.grey[700],
                          height: 1.35,
                        ),
                      ),
                      12.verticalSpace,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: otaController.pickLocalFirmwareFile,
                              icon: const Icon(Icons.folder_open, size: 18),
                              label: Text(
                                otaState.selectedImage == null
                                    ? 'Install from file (.bin)'
                                    : 'Change .bin file',
                                style: TextStyle(fontSize: 12.spMin),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryColor,
                                side: const BorderSide(
                                  color: AppColors.primaryColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            ),
                          ),
                          if (otaState.selectedImage != null) ...[
                            10.horizontalSpace,
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (batteryOk && streamingOk)
                                    ? otaController.startFirmwareUpload
                                    : null,
                                icon: const Icon(
                                  Icons.upload_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Start OTA Upload',
                                  style: TextStyle(
                                    fontSize: 12.spMin,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _phaseTitle(OtaPhase phase) {
    switch (phase) {
      case OtaPhase.uploading:
        return 'Uploading Firmware via SMP (mcumgr)';
      case OtaPhase.markingTestOnly:
        return 'Marking Slot 1 for Test-Only Swap';
      case OtaPhase.resetting:
        return 'Resetting CHORD Unit';
      case OtaPhase.swappingAndRebooting:
        return 'MCUboot Image Swap in Progress';
      case OtaPhase.reconnecting:
        return 'Waiting for CHORD & Reconnecting';
      case OtaPhase.idle:
      case OtaPhase.readyToUpload:
      case OtaPhase.succeeded:
      case OtaPhase.rolledBack:
      case OtaPhase.failed:
        return 'Firmware Update';
    }
  }

  Widget _buildMetaRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.spMin,
            color: Colors.grey[600],
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.spMin,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
