import 'package:cord_hearing/src/controller/device_pairing_view_controller.dart';
import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:cord_hearing/src/core/widgets/dialog_sheet.dart';
import 'package:cord_hearing/src/view/dashboard/dashboard_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

class DevicePairingView extends ConsumerWidget {
  const DevicePairingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(bluetoothScanProvider, (previous, next) {
      if (next.status == BluetoothScanStatus.connected) {
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const DashboardView(),
          ),
        );
      }
    });

    final scanState = ref.watch(bluetoothScanProvider);
    final isScanning = scanState.status == BluetoothScanStatus.scanning;

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
                GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const DashboardView(),
                      ),
                    );
                  },
                  child: Center(
                    child: Stack(
                      children: [
                        Lottie.asset(
                          AppAssets.pulseAnimation,
                          height: 220.h,
                          repeat: true,
                          animate: true,
                        ),
                        SvgPicture.asset(
                          AppAssets.bluetoothScanning,
                          height: 220.h,
                        ),
                      ],
                    ),
                  ),
                ),
                24.verticalSpace,
                Text(
                  'Make sure your hearing device is turned on and Bluetooth is enabled on your phone. Keep your device close to your phone while we search for and connect to it.',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 14.spMin,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                24.verticalSpace,
                Center(
                  child: SizedBox(
                    width: 200.w,
                    height: 52.h,
                    child:
                        isScanning ||
                            scanState.status == BluetoothScanStatus.connecting
                        ? ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C757D),
                              disabledBackgroundColor: const Color(0xFF6C757D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26.r),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isScanning ? 'Scanning' : 'Connecting...',
                                  style: TextStyle(
                                    fontSize: 16.spMin,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                                8.horizontalSpace,
                                const CupertinoActivityIndicator(
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          )
                        : AppButton(
                            text: 'Scan',
                            onPressed: () {
                              ref
                                  .read(bluetoothScanProvider.notifier)
                                  .startScan();
                            },
                          ),
                  ),
                ),
                if (scanState.errorMessage != null) ...[
                  16.verticalSpace,
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14).r,
                    decoration: BoxDecoration(
                      color: scanState.requiresPairingMode
                          ? Colors.amber.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: scanState.requiresPairingMode
                            ? Colors.amber[800]!
                            : Colors.red,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          scanState.requiresPairingMode
                              ? Icons.bluetooth_searching
                              : Icons.error_outline,
                          color: scanState.requiresPairingMode
                              ? Colors.amber[900]
                              : Colors.red,
                          size: 20.spMin,
                        ),
                        8.horizontalSpace,
                        Expanded(
                          child: Text(
                            scanState.errorMessage!,
                            style: TextStyle(
                              color: scanState.requiresPairingMode
                                  ? Colors.amber[900]
                                  : Colors.red,
                              fontSize: 13.spMin,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // System Connected Devices Section
                if (scanState.systemDevices.isNotEmpty) ...[
                  32.verticalSpace,
                  Text(
                    'Connected to Phone (Hearing Aid / Audio)',
                    style: TextStyle(
                      fontSize: 16.spMin,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  12.verticalSpace,
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFB9DCF7)),
                    ),
                    child: Column(
                      children: List.generate(
                        scanState.systemDevices.length,
                        (index) {
                          final device = scanState.systemDevices[index];
                          return _DeviceListItem(
                            device: device,
                            isSystemDevice: true,
                          );
                        },
                      ),
                    ),
                  ),
                ],
                32.verticalSpace,
                Text(
                  isScanning
                      ? 'Looking for available devices'
                      : 'Available Devices',
                  style: TextStyle(
                    fontSize: 18.spMin,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                16.verticalSpace,
                if (!isScanning)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child:
                        scanState.devices.isEmpty &&
                            scanState.status == BluetoothScanStatus.scanned &&
                            scanState.systemDevices.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24).r,
                            child: Center(
                              child: Text(
                                'No CHORD devices found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.spMin,
                                ),
                              ),
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final connectableDevices = scanState.devices;
                              final itemCount = connectableDevices.length;

                              return Column(
                                children: List.generate(
                                  itemCount,
                                  (index) {
                                    final scanResult =
                                        connectableDevices[index];
                                    final device = scanResult.device;

                                    return Column(
                                      children: [
                                        _DeviceListItem(
                                          device: device,
                                          rssi: scanResult.rssi,
                                        ),
                                        if (index < itemCount - 1)
                                          Divider(
                                            height: 1,
                                            color: Colors.grey.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
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

class _DeviceListItem extends ConsumerWidget {
  const _DeviceListItem({
    required this.device,
    this.isSystemDevice = false,
    this.rssi,
  });

  final BluetoothDevice device;
  final bool isSystemDevice;
  final int? rssi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(bluetoothScanProvider);
    final isConnecting = scanState.status == BluetoothScanStatus.connecting;

    var name = device.platformName;
    if (name.isEmpty) {
      name = 'CHORD Body Unit';
    }

    final deviceId = device.remoteId.str.isEmpty
        ? 'Unknown ID'
        : device.remoteId.str;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16).r,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.spMin,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isSystemDevice) ...[
                      6.horizontalSpace,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ).r,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2BA9E0,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'Paired',
                          style: TextStyle(
                            fontSize: 10.spMin,
                            color: const Color(0xFF2BA9E0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                4.verticalSpace,
                Row(
                  children: [
                    Text(
                      deviceId,
                      style: TextStyle(
                        fontSize: 13.spMin,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (rssi != null) ...[
                      8.horizontalSpace,
                      Text(
                        '${rssi}dBm',
                        style: TextStyle(
                          fontSize: 11.spMin,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          FittedBox(
            // height: 36.h,
            // width: 100.w,
            child: ElevatedButton(
              onPressed: isConnecting
                  ? null
                  : () => _showConnectDialog(context, ref, device),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B5C7F),
                disabledBackgroundColor: Colors.grey,
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

  void _showConnectDialog(
    BuildContext context,
    WidgetRef ref,
    BluetoothDevice device,
  ) {
    var deviceName = device.platformName;
    if (deviceName.isEmpty) {
      deviceName = 'CHORD Hearing Unit';
    }

    showSizeSheet(
      context,
      Padding(
        padding: const EdgeInsets.all(24).r,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                text: 'Connect to ',
                style: TextStyle(
                  fontSize: 20.spMin,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontFamily: 'Inter',
                ),
                children: [
                  TextSpan(
                    text: deviceName,
                    style: const TextStyle(
                      color: Color(0xFF2BA9E0),
                    ),
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            Text(
              "Before connecting, ensure your CHORD unit is turned on. If this phone hasn't paired before, hold VOL+ and VOL− together for 3 seconds on the unit.",
              style: TextStyle(
                fontSize: 14.spMin,
                color: const Color(0xFF666666),
                height: 1.5,
              ),
            ),
            32.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD2D6DC),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16.spMin,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
                16.horizontalSpace,
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref
                            .read(bluetoothScanProvider.notifier)
                            .connectToDevice(device);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2BA9E0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26.r),
                        ),
                      ),
                      child: Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 16.spMin,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            16.verticalSpace,
          ],
        ),
      ),
    );
  }
}
