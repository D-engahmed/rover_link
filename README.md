# Rover Link

Flutter control application for an HC-05 / STM32F401 rover.

Rover Link provides:

- Manual drive controls
- Follow-Me control mode
- Bluetooth Classic SPP connection flow
- Global obstacle/safety strip with latching e-stop
- Serial TX/RX console
- Phone-camera face detection for Follow-Me bearing
- Door trigger guarded by face centering, head orientation and ultrasonic distance
- A transport abstraction so demo and real Bluetooth implementations stay separate

## Current engineering status

The repository has been hardened around the real control path, but **hardware validation is still required**. The GitHub repository cannot prove that a particular STM32 firmware parser, HC-05 module configuration, motor driver, servo wiring, or sensor is correct.

The following changes are now in the repository:

- Demo Bluetooth is opt-in instead of silently pretending to be a real rover connection.
- Android Bluetooth Classic and camera permissions are declared.
- Android application and plugin modules are forced to compile against SDK 36.
- Bluetooth RX is line-buffered with a bounded buffer.
- Real Bluetooth TX adds CRLF framing for the line-oriented rover protocol.
- Disconnecting forces Follow-Me back to Manual and clears the logical door-open state.
- E-stop attempts a raw STOP command before locking drive input.
- Movement is blocked when the ultrasonic distance is below the critical threshold.
- Camera startup failures are surfaced instead of crashing the control state.
- The stale generated Flutter counter test has been replaced with a Rover Link smoke test.
- GitHub Actions now runs `flutter pub get`, `flutter analyze`, and `flutter test` on pushes and pull requests.

## Requirements

The project declares Dart `>=3.12.0` and Flutter `>=3.44.0` in `pubspec.yaml`.

For real rover control you need:

- Android phone
- HC-05 configured for Bluetooth Classic SPP
- STM32F401 rover controller
- UART connection between HC-05 and STM32
- Ultrasonic sensor if obstacle telemetry is enabled
- Servo/actuator if the door workflow is used

`bluetooth_classic` is an Android Bluetooth Classic serial plugin and exposes paired-device discovery, scanning, connect/disconnect, read and write operations. citeturn0view0

## Install and run

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

For a real Android phone:

```bash
flutter run
```

The application defaults to the **real Bluetooth transport**. This is deliberate: a development build must not report a fake rover connection unless the developer explicitly asks for the simulator.

### Demo mode

Use the simulator explicitly:

```bash
flutter run --dart-define=ROVER_DEMO=true
```

The demo transport produces simulated devices and telemetry. It does not communicate with the HC-05.

## Android permissions

`android/app/src/main/AndroidManifest.xml` declares:

- `BLUETOOTH_SCAN`
- `BLUETOOTH_CONNECT`
- legacy `BLUETOOTH` / `BLUETOOTH_ADMIN` for Android 11 and below
- `ACCESS_FINE_LOCATION` for legacy Bluetooth scanning
- `CAMERA`

The Bluetooth plugin also initializes its runtime permissions through `initPermissions()`. citeturn0view0

## Camera / ML Kit

The camera package supports image streaming from Dart and requires camera permission. Current camera documentation also notes that applications must handle camera lifecycle changes themselves; this project therefore keeps camera ownership inside `VisionService` rather than spreading it through the UI. citeturn0view1

Face detection is used for:

1. Detecting whether a person is in frame
2. Estimating horizontal bearing from the face bounding box
3. Reading head yaw to determine whether the person is approximately facing the rover

ML Kit Face Detection is a mobile-only native bridge; it is not a general web implementation. citeturn1view1

## Safety model

The app has two layers of safety:

### UI/state safety

- E-stop is latched.
- Drive commands are rejected while e-stopped.
- Drive commands are rejected when the obstacle reading is below `obstacleCriticalCm`.
- Losing the Bluetooth connection exits Follow-Me mode.
- Door opening is rejected while disconnected or e-stopped.

### Firmware safety

The STM32 firmware **must implement its own safety rules**. The phone is not a safety controller. A Bluetooth disconnect, app crash, battery failure, RF interference, or malicious command must not leave motors running.

## Protocol boundary

The current protocol tokens remain provisional because the repository does not contain a verified STM32 UART parser.

Current app-side values are centralized in `lib/constants.dart`:

```text
CMD:F / CMD:B / CMD:L / CMD:R / CMD:S
PWM:<0..255>
DOOR_OPEN
DOOR_CLOSE
```

The telemetry parser currently recognizes the prototype forms:

```text
+US:<cm>cm
+DIST:<m>m
+RSSI:<dbm>
```

These are **not evidence of the real firmware protocol**. Before hardware acceptance, document the actual STM32 parser and make the app and firmware share one explicit protocol specification.

## Follow-Me logic

### Gradient/RSSI prototype

The app can compare successive distance samples and expose a simple search/hold state. This is a prototype control strategy, not a robust autonomous navigation algorithm.

### Camera mode

Camera mode selects the largest detected face and derives:

- `bearingFrac`: horizontal position in the frame
- `sizeFrac`: face size relative to frame height
- `headYawDeg`: ML Kit head yaw
- `facingCamera`: yaw within the configured threshold

The door trigger requires all of these conditions:

1. A face is present.
2. The face is centered.
3. The person is facing the camera.
4. Ultrasonic distance is within `doorApproachCm`.
5. Bluetooth is connected.
6. E-stop is not active.

## Hardware limitation: material classification

A standard HC-SR04-class ultrasonic sensor supplies time-of-flight distance. It does not expose enough information for the application to reliably classify a target as human, metal, wall, etc.

If material classification becomes a requirement, it needs an additional sensing modality such as camera/depth/ToF/radar. Do not try to infer material class from one ultrasonic distance value.

## Architecture

```text
lib/
├── constants.dart
├── main.dart
├── services/
│   ├── bt_service.dart          # transport interface + demo transport
│   ├── real_bt_service.dart     # HC-05 / Bluetooth Classic implementation
│   └── vision_service.dart      # camera + ML Kit perception
├── state/
│   └── rover_state.dart         # control state, safety and protocol handling
├── screens/
│   └── home_screen.dart
└── widgets/
    ├── controls.dart
    ├── connect_sheet.dart
    ├── console_drawer.dart
    └── follow_me_panel.dart
```

The UI does not import the Bluetooth plugin directly. Hardware-specific behavior remains behind `BtService`.

## Verification policy

Do not describe this project as hardware-verified until these checks have passed on the target phone and rover:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Then perform a physical acceptance test:

1. Pair the HC-05 with Android.
2. Scan and select the HC-05.
3. Connect.
4. Confirm TX commands arrive at the STM32.
5. Confirm STM32 telemetry arrives and is parsed.
6. Confirm STOP immediately disables motion.
7. Disconnect Bluetooth while motors are active and verify firmware-side fail-safe stop.
8. Move an obstacle below the critical threshold and verify the rover stops.
9. Test camera detection with the phone mounted in its real rover position.
10. Test the door trigger only after the previous safety checks pass.

## Important unresolved hardware decisions

These remain intentionally explicit rather than being guessed:

- Exact STM32 UART command grammar
- PWM/motor-driver protocol
- Servo open/close command or angle
- Exact ultrasonic telemetry format
- HC-05 baud configuration and firmware UART settings
- Firmware behavior on Bluetooth timeout/disconnect
- Whether Follow-Me should be autonomous or only provide steering recommendations

The next major engineering step should therefore be to define the **STM32 ↔ HC-05 wire protocol** and implement the matching firmware parser. That is more important than adding another UI feature.
