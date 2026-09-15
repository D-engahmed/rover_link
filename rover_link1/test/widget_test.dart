import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rover_link1/main.dart';
import 'package:rover_link1/widgets/radar_scope.dart';

void main() {
  testWidgets('Multi-screen navigation test: Home -> Drive -> Radar -> Home', (WidgetTester tester) async {
    await tester.pumpWidget(const RoverApp());

    // AppStartScreen intentionally shows a lightweight 1.05s visual splash.
    // The previous test asserted Home immediately after pumpWidget(), so it
    // was actually testing the splash screen and failed on the Home branding.
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    // Home Screen loads after the splash.
    expect(find.text('SMART ROVER'), findsOneWidget);
    expect(find.text('LIVE ENVIRONMENT'), findsOneWidget);
    expect(find.text('MISSION'), findsOneWidget);

    // Navigate to DRIVE.
    await tester.tap(find.text('Drive').first);
    await tester.pumpAndSettle();

    expect(find.text('MANUAL DRIVE'), findsOneWidget);
    expect(find.text('DIRECT MOTOR CONTROL'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('SPEED'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('OBSTACLE'), findsOneWidget);
    expect(find.text('CLEAR'), findsOneWidget);
    expect(find.text('ULTRASONIC'), findsOneWidget);
    expect(find.text('167 cm'), findsOneWidget);

    // Navigate to LIVE RADAR.
    await tester.tap(find.text('Radar').first);
    await tester.pumpAndSettle();

    expect(find.text('LIVE RADAR'), findsOneWidget);
    expect(find.text('AUTONOMOUS ROVER SYSTEM'), findsOneWidget);
    expect(find.text('NEAREST OBSTACLE'), findsOneWidget);
    expect(find.text('2.10'), findsOneWidget);
    expect(find.text('TRACKED OBJECTS'), findsOneWidget);
    expect(find.text('DETECTIONS'), findsOneWidget);
    expect(find.text('Target — YOU'), findsOneWidget);
    expect(find.text('Obstacle 1'), findsOneWidget);
    expect(find.text('Obstacle 2'), findsOneWidget);

    // Return to HOME.
    await tester.tap(find.text('Home').first);
    await tester.pumpAndSettle();

    expect(find.text('SMART ROVER'), findsOneWidget);
    expect(find.text('LIVE ENVIRONMENT'), findsOneWidget);
    expect(find.text('MISSION'), findsOneWidget);
  });

  testWidgets('RadarScope layout does not crash with zero or narrow constraints', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 0,
          height: 0,
          child: RadarScope(detections: []),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
