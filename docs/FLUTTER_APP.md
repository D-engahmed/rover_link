# Flutter application

The Flutter project lives in rover_link1/.

## Toolchain

The repository configuration uses:

- Flutter stable 3.35.0 in CI;
- Dart SDK compatible with ^3.12.2;
- flutter_classic_bluetooth;
- path_provider;
- Java 17 for Android CI.

The Android application ID is still com.example.rover_link1 and release builds currently use the debug signing configuration. Those values are not production distribution settings.

## Application shell

main.dart creates shared services inside MainNavigationScreen:

~~~text
BluetoothService
      ↓
RoverCommandService

BluetoothService
      ↓
RoverTelemetryService
      ↓
RoverTelemetry stream

RoverTelemetryService + RoverCommandService
      ↓
RoverAiService

RoverDatasetService
      ↓
local JSONL
~~~

The design prevents individual screens from creating competing rover-control sessions.

## Screens

### Home

Provides the control-center surface:

- link status;
- live perception;
- connection/sensor/control indicators;
- control-mode selection;
- safety messaging.

### Drive

Direct manual motor control:

- forward;
- backward;
- left;
- right;
- stop;
- speed.

### Radar

Renders the scan/perception visualization.

Live telemetry should be distinguished from mock/demo detection data whenever the visualization uses static examples.

### AI Autopilot

Shows:

- runtime state;
- deterministic AI decision;
- confidence;
- directional scores;
- current sensor input;
- last AI wire command;
- Bluetooth TX result;
- TX latency;
- command trace;
- explicit STM32 execution ACK status.

The current screen correctly labels execution ACK as not implemented.

### Settings

Provides Bluetooth support checks, enabled-state checks, scanning, connecting, and disconnecting.

### Mode screen

Provides dedicated Manual, Assisted, Autonomous, Follow Me, and Emergency Stop semantics.

### Command Monitor

Provides a filtered event history by source and stage.

## Mode semantics

| Mode | Source of movement decision |
|---|---|
| Manual | human |
| Assisted | human, with phone-side forward safety check |
| Autonomous | phone-side deterministic policy |
| Follow Me | phone-side target-distance/angle policy |
| Emergency Stop | explicit stop path |

## Manual transition

The app does not merely navigate to Drive.

It performs:

~~~text
stop AI/follow controller
        ↓
send P
        ↓
send M
        ↓
switch Drive screen
~~~

This ordering prevents an old autonomous subscription from issuing another movement command after the user expects manual control.

## Telemetry flow

After Bluetooth becomes ready:

~~~text
Bluetooth input
      ↓
newline-delimited messages
      ↓
RoverTelemetryService
      ↓
JSON decode
      ↓
RoverTelemetry.fromJson()
      ↓
UI + AI + dataset
~~~

Non-JSON lines are currently ignored. That is appropriate for mixed development logs, but a production protocol should report malformed frames explicitly.

## Command tracing

Every command is recorded through the command service as:

~~~text
PROPOSED → APPROVED → QUEUED → SENT
                         └────→ FAILED
~~~

Sources are:

- HUMAN
- AI
- SAFETY
- SYSTEM

BLOCKED is supported by the model but is not yet a primary admission result in sendCommand itself.

## Local data collection

RoverDatasetService records JSONL fields for:

- timestamp;
- session ID;
- front/left/right distances;
- target distance/angle;
- speed;
- RSSI;
- previous action;
- controller;
- action;
- human override;
- notes.

The file lives in the application documents directory.

## Android permissions

The Android manifest declares Bluetooth classic, scan, and connect permissions plus legacy location permission for Android versions up to API 30.

## Testing

Current Flutter tests cover startup/navigation and basic baseline behavior.

Recommended next tests:

- command-service fake transport;
- malformed telemetry;
- missing/zero telemetry values;
- mode transition races;
- exact watchdog boundaries;
- command trace lifecycle;
- protocol codec/CRC;
- ACK correlation when available.

## Current app-level limitations

- no current camera/vision service;
- no complete automatic reconnect state machine;
- target and RSSI fields are broader than current firmware telemetry;
- Bluetooth write success is not hardware execution proof;
- two baseline controllers use different safety thresholds.
