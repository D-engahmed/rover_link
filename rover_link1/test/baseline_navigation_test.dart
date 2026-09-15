import 'package:flutter_test/flutter_test.dart';

import '../lib/models/rover_telemetry.dart';
import '../lib/services/baseline_navigation_service.dart';
import '../lib/services/rover_command_service.dart';
import '../lib/services/bluetooth_service.dart';

void main() {
  test('stops when front distance is unsafe', () {
    final controller = BaselineNavigationService(
      RoverCommandService(BluetoothService()),
    );

    final state = RoverTelemetry(
      timestampMs: 1,
      frontDistanceCm: 10,
      targetAngleDeg: 90,
    );

    expect(controller.decide(state), 'STOP');
  });

  test('moves forward on a clear front path', () {
    final controller = BaselineNavigationService(
      RoverCommandService(BluetoothService()),
    );

    final state = RoverTelemetry(
      timestampMs: 1,
      frontDistanceCm: 100,
      targetAngleDeg: 90,
    );

    expect(controller.decide(state), 'FORWARD');
  });
}
