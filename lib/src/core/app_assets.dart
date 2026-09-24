class AppAssets {
  static const String _basePath = 'assets';
  static const String splashBg = '$_basePath/splash_bg.svg';
  static const String splashLogo = '$_basePath/splash_logo.svg';
  static const String logoIcon = '$_basePath/logo_icon.svg';
  static const String bluetoothScanning = '$_basePath/bluetooth_scanning.svg';
  static const String bluetoothScanningFailed = '$_basePath/bluetooth_scanning_failed.svg';

  static String onboardingGrid(int val) =>
      '$_basePath/onboarding_grid_$val.png';
}
