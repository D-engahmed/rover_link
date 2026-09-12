# rover_link

Smart Autonomous Rover — unified mobile control app built with Flutter.

The phone is the high-level command / AI interface for an STM32F401 rover over
Bluetooth (HC-05). One system, one state model, two interfaces (mobile app +
onboard TFT).

## Screens

- **Mission Control (Home)** — live radar, target, mission state, emergency stop
- **Drive** — manual / assisted joystick control with speed
- **Radar** — full-screen live environment sweep
- **AI** — localization, prediction, navigation decision, confidence
- **Telemetry** — real-time link and sensor data
- **Settings** — bluetooth, mission, safety, calibration

## Getting Started

```bash
flutter pub get
flutter run
```

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.