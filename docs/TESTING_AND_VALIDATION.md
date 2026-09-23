# Testing and validation

## Current automated coverage

### Flutter

rover_link1/test/ contains:

- baseline_navigation_test.dart;
- widget_test.dart.

The widget suite covers:

- splash timing;
- Home startup;
- Home → Drive;
- Drive UI;
- Drive → Radar;
- Radar content;
- return to Home;
- RadarScope under zero/narrow constraints.

The baseline test covers unsafe forward distance and clear-path forward behavior.

### Python

ml/baseline/test_controller.py covers baseline cases including:

- close front turning;
- both sides blocked;
- missing front distance.

### CI

.github/workflows/android-apk.yml is configured for:

- pushes to main;
- feat/** branch pushes;
- pull requests to main;
- manual dispatch.

It installs Java 17 and Flutter 3.35.0, then runs:

~~~text
flutter pub get
flutter analyze
flutter build apk --release
~~~

and uploads the release APK.

No current GitHub Actions run was available in the repository audit for the inspected HEAD, so the repository should not be described as having a currently verified green CI run.

## What software tests cannot prove

Automated tests cannot establish:

- actual Bluetooth radio behavior;
- physical stop distance;
- sensor electrical correctness;
- motor-driver fail-safe state;
- watchdog behavior under real link loss;
- servo endpoint safety;
- door stall/pinch safety;
- real-world perception accuracy.

## Hardware validation sequence

### Stage 1 — bench, wheels off the ground

Verify:

- firmware boot;
- Bluetooth pairing;
- telemetry;
- manual commands;
- STOP;
- Manual ↔ Phone Autonomy transitions;
- phone command-age timeout.

### Stage 2 — obstacle tests

Verify:

- clear valid sensor permits forward;
- unsafe distance blocks/stops forward;
- zero/no-echo cannot authorize forward;
- turning behavior remains predictable.

### Stage 3 — low-speed floor tests

Measure:

- command latency;
- actual stopping distance;
- mode switching;
- Bluetooth disconnect behavior;
- phone-app crash behavior.

### Stage 4 — replay

Replay recorded telemetry through the navigation controller without motors.

Compare decisions with known human/baseline actions.

### Stage 5 — learned policy

Run the learned policy disconnected from motors first.

Then:

1. compare with baseline;
2. test edge cases;
3. enforce an external safety veto;
4. test at conservative speed;
5. record failures with telemetry.

## Evidence to retain

For safety or model-validation runs, retain:

- firmware commit;
- Flutter build/commit;
- hardware revision;
- sensor configuration;
- test date;
- environment;
- scenario;
- expected result;
- observed result;
- telemetry;
- command trace;
- video where practical.

A statement such as "it worked" is not adequate validation evidence.

## Priority test gaps

1. fake Bluetooth transport for command-service tests;
2. malformed telemetry tests;
3. timestamp and missing-field tests;
4. mode-race tests;
5. watchdog boundary tests;
6. APP/SAFETY unit tests;
7. protocol codec/CRC tests;
8. ACK correlation tests after protocol migration.
