# Rover Link mobile application

This directory contains the Flutter Android application for Rover Link.

## Responsibilities

The app is the operator/control and data-collection node.

It provides:

- Bluetooth discovery and connection;
- manual driving;
- assisted driving;
- phone-side deterministic autonomy;
- Follow Me control from target telemetry;
- live telemetry and radar visualization;
- command-source/lifecycle tracing;
- local JSONL dataset recording.

## Runtime architecture

~~~text
BluetoothService
      ↓
RoverCommandService
      ↓
STM32 commands

BluetoothService
      ↓
RoverTelemetryService
      ↓
RoverTelemetry
      ├→ UI
      ├→ RoverAiService
      └→ RoverDatasetService
~~~

Long-lived services are created by the main navigation shell and shared across screens.

## Important boundaries

- The STM32 remains the final hardware safety authority.
- SENT means Bluetooth write success, not hardware execution.
- The current autonomous controller is deterministic; the PPO experiment under rover_rl/ is not integrated here.
- Follow Me currently expects target distance/angle telemetry; no camera/vision service is present in this tree.
- The active command protocol is single-byte, not yet the framed CRC protocol.

## Development

Use the Flutter toolchain documented in the root project documentation:

~~~bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
~~~

See ../docs/FLUTTER_APP.md for the full application architecture and ../docs/TESTING_AND_VALIDATION.md for validation requirements.
