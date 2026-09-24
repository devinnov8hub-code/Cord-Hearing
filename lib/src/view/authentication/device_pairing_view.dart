import 'package:cord_hearing/src/controller/device_pairing_view_controller.dart';
import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:cord_hearing/src/core/widgets/dialog_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class DevicePairingView extends ConsumerWidget {
  const DevicePairingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Center(
                    child: Text(
                      scanState.errorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14.spMin,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                48.verticalSpace,
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
                            scanState.status == BluetoothScanStatus.scanned
                        ? Padding(
                            padding: const EdgeInsets.all(24).r,
                            child: Center(
                              child: Text(
                                'No devices found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.spMin,
                                ),
                              ),
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final isMock = scanState.devices.isEmpty;
                              final connectableDevices = scanState.devices
                                  .where(
                                    (e) =>
                                        e.advertisementData.connectable == true,
                                  )
                                  .toList();

                              final itemCount = isMock
                                  ? 3
                                  : connectableDevices.length;

                              return Column(
                                children: List.generate(
                                  itemCount,
                                  (index) {
                                    String deviceName;
                                    BluetoothDevice? currentDevice;
                                    if (isMock) {
                                      deviceName = [
                                        'AID-4435-5e',
                                        'AID-6721-9x',
                                        'AID-9813-4k',
                                      ][index];
                                    } else {
                                      final device =
                                          connectableDevices[index].device;
                                      currentDevice = device;
                                      deviceName =
                                          device.platformName.isNotEmpty
                                          ? device.platformName
                                          : device.remoteId.str;
                                    }

                                    return Column(
                                      children: [
                                        _DeviceListItem(
                                          name: deviceName,
                                          device: currentDevice,
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
  const _DeviceListItem({required this.name, this.device});
  final String name;
  final BluetoothDevice? device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(bluetoothScanProvider);
    final isConnecting = scanState.status == BluetoothScanStatus.connecting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20).r,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16.spMin,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            height: 36.h,
            width: 100.w,
            child: ElevatedButton(
              onPressed: isConnecting
                  ? null
                  : () => _showConnectDialog(context, ref, name, device),
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
    String deviceName,
    BluetoothDevice? device,
  ) {
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
                  fontFamily:
                      'Inter', // Defaulting to the standard font style if any
                ),
                children: [
                  TextSpan(
                    text: deviceName,
                    style: const TextStyle(
                      color: Color(0xFF2BA9E0), // AppColors.primaryColor
                    ),
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            Text(
              'Before connecting, please check that the Device ID\nshown above matches the ID on your hearing device\nor its packaging.',
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
