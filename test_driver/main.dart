// Test-only entrypoint that enables the Flutter Driver extension so the app
// can be driven interactively (taps, text entry, screenshots) on a simulator.
// Run with: flutter run -t test_driver/main.dart
import 'package:cord_hearing/main.dart' as app;
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  app.main();
}
