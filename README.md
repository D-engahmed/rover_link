# rover_link

Unified Smart Autonomous Rover control app — the mobile-app half of a single
Human ↔ AI ↔ Rover interface. The other half is the STM32F401 + ST7735 TFT
display on the rover itself; both share the same visual language and the
same underlying state model (mode, mission status, target telemetry).

## Concept

The app is organized around **missions**, not disconnected screens. A
mission (e.g. `FOLLOW USER`) drives what's shown across Home, Drive, Radar,
and AI — they're different views of one state machine, not separate tools.

Control modes: `MANUAL` → `ASSISTED` → `FOLLOW ME` → `AUTONOMOUS`.
Safety-critical decisions (obstacle stop) live on the STM32, never the phone
— the app only visualizes rover-reported state.

## Structure

```
lib/
  main.dart                 // app entry + bottom-nav shell
  theme/app_theme.dart       // color palette + ThemeData (matches the HTML prototype)
  models/rover_state.dart    // shared state: mode, mission, target, telemetry
  widgets/radar_view.dart    // animated radar (CustomPainter): sweep, target, obstacles
  widgets/metric_tile.dart   // shared card/tile/row building blocks
  screens/home_screen.dart   // Mission Control — status, radar, mode, mission, e-stop
  screens/drive_screen.dart  // Manual / Assisted drive pad + speed
  screens/radar_screen.dart  // Full-screen radar + detection list
  screens/ai_screen.dart     // Localization, navigation decision, telemetry pipeline
  screens/settings_screen.dart // Bluetooth device picker + connect/disconnect + parameters
  services/rover_link_protocol.dart // wire format between phone and STM32 (see below)
  services/bluetooth_service.dart   // classic-Bluetooth (SPP) connection to the HC-05
  services/navigation_ai.dart       // signal smoothing + follow-me decision logic
```

## Connecting to the rover

The HC-05 is a **classic Bluetooth (SPP)** module, not BLE, so the app uses
`flutter_bluetooth_serial` rather than a BLE package — and this means
**Android only**: iOS doesn't let third-party apps open the classic SPP
profile without MFi hardware certification. To support iOS later, the
rover side would need a BLE module instead (e.g. HM-10, or the STM32's own
BLE if it has one) — no phone-side fix can work around Apple's restriction.

Flow: pair the HC-05 in the phone's OS-level Bluetooth settings first
(default PIN is usually `1234` or `0000`), then use Settings → Bluetooth /
HC-05 in the app to pick it from the paired-devices list and connect.

### Wire protocol (assumed — adjust to match your firmware)

No firmware spec was provided, so `rover_link_protocol.dart` assumes
newline-delimited JSON, one object per line, in both directions:

```
STM32 -> phone (telemetry):
{"t":"telemetry","tgt_d":4.72,"tgt_b":27,"us_cm":84,"servo":74,"motor":48}

phone -> STM32 (commands):
{"cmd":"set_mode","mode":"follow_me"}
{"cmd":"drive","dir":"forward","speed":62}
{"cmd":"estop"}
{"cmd":"resume"}
```

If your firmware already speaks something else, only
`rover_link_protocol.dart` and `bluetooth_service.dart` need to change —
nothing else in the app depends on the wire format directly.

### The "AI" (`navigation_ai.dart`)

This is a **rule-based follow-me controller**, not a trained ML model: it
exponential-smooths the noisy raw distance/bearing readings, derives a
confidence score from how much they're jittering, and turns that into a
steering decision (forward / turn / stop / avoid / search) with a
speed that eases off as the rover nears the follow distance. Obstacle
avoidance always overrides following. If you want an actual trained model
later (e.g. calibrating RSSI→distance from real logged readings), this is
the file to swap — `update()`/`decide()` are the only two methods anything
else in the app calls.

## Status

Five screens render and are wired to one shared `RoverState`. A live
HC-05 connection now feeds `RoverState` directly and runs `NavigationAI` on
the incoming telemetry; when nothing's connected it falls back to a
simulated telemetry tick so the UI is never dead on screen. Not yet done:

- [ ] Confirm the wire protocol above against your actual STM32 firmware
      and adjust `rover_link_protocol.dart` if it differs
- [ ] Android manifest permissions for Bluetooth (see note below)
- [ ] Matching ST7735 firmware UI on the STM32 side
- [ ] Persisting mission parameters (follow distance, obstacle threshold)
      from Settings into `NavigationAI` instead of its hardcoded defaults

**Android permissions**: once `flutter create` generates
`android/app/src/main/AndroidManifest.xml`, add `BLUETOOTH_CONNECT` (and
`BLUETOOTH_SCAN` if you add device discovery beyond paired devices) for
Android 12+, plus the legacy `BLUETOOTH`/`BLUETOOTH_ADMIN` permissions for
older versions.

## Getting started

This repo currently contains hand-written `lib/` sources and `pubspec.yaml`
only — no platform folders yet. To run it:

```bash
flutter create --org com.nxgai --project-name rover_link .   # generates android/ ios/ etc. without touching lib/
flutter pub get
flutter run
```
