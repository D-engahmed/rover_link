# Rover Link — Flutter app

One screen, Manual/Follow-Me mode switch (not tabs), global safety strip +
latching e-stop, collapsible serial console, a Bluetooth connect flow that
mimics real scan → connect → manage/disconnect behavior, and — new — a
camera-based "find the person, check their stance, open the door" pipeline
for Follow Me mode.

## What's verified vs. not

Written in a sandbox with **no Flutter SDK and no network access to
pub.dev** — nothing here has been run, `flutter analyze`'d, or compiled.
Package APIs (`bluetooth_classic`, `camera`, `google_mlkit_face_detection`)
were checked against published docs/examples via live search, not the
actual installed packages. Run it and send me whatever `flutter pub get` /
`flutter run` throws — the likely trouble spots are isolated on purpose:
`lib/services/real_bt_service.dart` (Bluetooth) and
`lib/services/vision_service.dart` (camera → ML Kit image conversion, the
single most version-sensitive part of that file).

**Already learned the hard way this session:** `bluetooth_classic` failed to
build because its own Android module is pinned to compileSdk 31 while its
transitive androidx dependencies now want 34+. If you hit that
`checkDebugAarMetadata` error again, tell me rather than assuming it's fixed
— the standard fix is forcing a newer compileSdk on all Android
subprojects from the root Gradle file, but the exact snippet depends on
whether your project uses Groovy or Kotlin DSL, and I'd rather confirm that
than hand you a second unverified guess.

## Setup

```
cd rover_link
flutter pub get
flutter run   # on a real Android device — emulators lack BT radios and most have no usable camera feed for face detection
```

`lib/constants.dart` has `useDemoBluetooth = true` by default, so it runs
immediately with simulated devices/telemetry, no rover needed. Camera mode
is independent of that flag — it only asks for camera permission and starts
the camera when you pick "CAMERA" as the bearing source in Follow Me.

## Android manifest

Add to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`,
before `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />

<!-- Android 11 (API 30) and below -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />

<!-- Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

Double-check `bluetooth_classic`'s own permissions section on pub.dev
matches this — I only had search snippets of its README, not the full page.

## Why object-type classification (wall/metal/human) isn't in here

Confirmed: you're on a standard HC-SR04-class module, which only exposes
time-of-flight — no echo waveform, no amplitude data. There's no signal
there to classify material from. That's a hardware ceiling, not a missing
feature. Person detection runs off the phone's camera instead
(`lib/services/vision_service.dart`, Google ML Kit Face Detection), which
also directly answers "is this person facing the rover" via
`headEulerAngleY` — your stance signal, built into the same detection call,
no separate pose model needed for v1.

## Door-open trigger (camera bearing mode only)

`RoverState._maybeOpenDoor()` fires once all three hold:
1. A face is detected and centered (`bearingFrac` within
   `centeredBearingThreshold`, default 0.12, of dead center)
2. `facingCamera` is true (head yaw within `facingYawThresholdDeg`, default
   20°, of facing the camera straight-on) — this is the stance check
3. Ultrasonic reads at or below `doorApproachCm` (default 100cm / ~1m)

All three live in `constants.dart` as starting guesses — tune them once you
can actually test the approach distance and angle you want.

## What's still a placeholder, not a decision I made for you

1. **Drive command bytes** (`cmdForward` etc., single chars `F/L/R/B/S`) —
   carried over from the HTML mock. Confirm against your STM32 UART parser.
2. **Door actuator commands** (`cmdDoorOpen`/`cmdDoorClose`) — you confirmed
   it's a servo on a PWM pin; these strings are stand-ins until you give me
   the actual angle/command values.
3. **Telemetry wire format** (`+US:<cm>cm`, `+DIST:<m>m` in
   `RoverState._onLine`) — invented for the mock. Replace with your real
   format.
4. **SPP UUID** — standard HC-05 default; only matters if reconfigured.
5. **`camera` / `google_mlkit_face_detection` version numbers** in
   `pubspec.yaml` — couldn't reach pub.dev to confirm exact current
   versions, only search snippets. `flutter pub get` will tell you
   immediately if either needs bumping — that's a one-line fix, not a
   design problem.

## Platform decision made for you, with reasoning

Android only. Classic Bluetooth SPP (what HC-05 speaks) requires Apple MFi
accessory certification to reach from an iOS app — HC-05 isn't MFi-certified
and can't be made so. iOS in scope later means a hardware change (a BLE
module instead of HC-05), not a Flutter package choice.

## Architecture

- `services/bt_service.dart` — `BtService` interface + `DemoBtService`
  (simulated, no dependency on the Bluetooth plugin at all).
- `services/real_bt_service.dart` — `RealBtService`, the only file that
  imports `bluetooth_classic`. Hardware-specific and unverified, isolated
  from the UI.
- `services/vision_service.dart` — camera + face detection, isolated the
  same way, for the same reason.
- `state/rover_state.dart` — single `ChangeNotifier` holding connection,
  safety, mode, e-stop, all three bearing sources, door state, and both
  logs.
- `screens/home_screen.dart` + `widgets/` — the UI, one screen,
  mode-switched body, no tab navigation.

## Backend

Lives separately in `rover_backend/` (own zip) — logging + model
versioning/serving, deliberately **not** in the real-time control path. See
its own README for why.
