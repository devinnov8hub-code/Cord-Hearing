import 'dart:io';

import 'package:cord_hearing/src/core/services/chord_ble_constants.dart';
import 'package:cord_hearing/src/view/dashboard/widgets/hearing_profile_card.dart';
import 'package:cord_hearing/src/view/dashboard/widgets/volume_level_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: ToastificationWrapper(
        child: ScreenUtilInit(
          designSize: const Size(383, 852),
          builder: (context, _) => MaterialApp(
            home: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  testWidgets('HearingProfileCard displays profiles and disconnected status',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const HearingProfileCard()));
    await tester.pumpAndSettle();

    expect(find.text('Sound Profile'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Noisy'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
  });

  testWidgets('HearingProfileCard does not switch profile when disconnected',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const HearingProfileCard()));
    await tester.pumpAndSettle();

    // Default profile is normal
    expect(find.text(ChordProfile.normal.description), findsOneWidget);

    // Tap Noisy button while disconnected
    await tester.tap(find.byKey(const Key('profile_noisy_button')));
    await tester.pump();

    // Still normal because device is disconnected
    expect(find.text(ChordProfile.normal.description), findsOneWidget);
    expect(find.text(ChordProfile.noisy.description), findsNothing);

    // Dismiss toast timers
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('VolumeLevelCard returns empty widget on iOS',
      (WidgetTester tester) async {
    if (Platform.isIOS) {
      await tester.pumpWidget(createTestWidget(const VolumeLevelCard()));
      await tester.pumpAndSettle();

      expect(find.text('Phone Audio Volume'), findsNothing);
    }
  });
}
