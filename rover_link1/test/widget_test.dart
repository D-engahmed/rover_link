import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rover_link1/main.dart';
import 'package:rover_link1/widgets/radar_scope.dart';

void main() {
  testWidgets('Multi-screen navigation test: Home -> Drive -> Radar -> Home', (WidgetTester tester) async {
    // Build RoverApp and trigger a frame
    await tester.pumpWidget(const RoverApp());

    // 1. Verify Home Screen loads initially
    expect(find.text('SMART ROVER'), findsOneWidget);
    expect(find.text('LIVE ENVIRONMENT'), findsOneWidget);
    expect(find.text('MISSION'), findsOneWidget);

    // 2. Navigate to DRIVE screen by tapping "Drive"
    await tester.tap(find.text('Drive').first);
    await tester.pump();

    // Verify DRIVE screen elements
    expect(find.text('MANUAL DRIVE'), findsOneWidget);
    expect(find.text('DIRECT MOTOR CONTROL'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);

    // D-Pad controls & STOP button
    expect(find.text('STOP'), findsOneWidget);

    // Speed panel
    expect(find.text('SPEED'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    // Obstacle and Ultrasonic panels
    expect(find.text('OBSTACLE'), findsOneWidget);
    expect(find.text('CLEAR'), findsOneWidget);
    expect(find.text('ULTRASONIC'), findsOneWidget);
    expect(find.text('167 cm'), findsOneWidget);

    // 3. Navigate from Drive to LIVE RADAR screen by tapping "Radar"
    await tester.tap(find.text('Radar').first);
    await tester.pump();

    // Verify LIVE RADAR screen is displayed
    expect(find.text('LIVE RADAR'), findsOneWidget);
    expect(find.text('AUTONOMOUS ROVER SYSTEM'), findsOneWidget);
    expect(find.text('NEAREST OBSTACLE'), findsOneWidget);
    expect(find.text('2.10'), findsOneWidget);
    expect(find.text('TRACKED OBJECTS'), findsOneWidget);
    expect(find.text('DETECTIONS'), findsOneWidget);
    expect(find.text('Target — YOU'), findsOneWidget);
    expect(find.text('Obstacle 1'), findsOneWidget);
    expect(find.text('Obstacle 2'), findsOneWidget);

    // 4. Navigate back to HOME screen by tapping "Home"
    await tester.tap(find.text('Home').first);
    await tester.pump();

    // Verify Home screen is visible again
    expect(find.text('SMART ROVER'), findsOneWidget);
    expect(find.text('LIVE ENVIRONMENT'), findsOneWidget);
    expect(find.text('MISSION'), findsOneWidget);
  });

  testWidgets('RadarScope layout does not crash with zero or narrow constraints', (WidgetTester tester) async {
    // Test with 0-width constraint
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
