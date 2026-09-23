# Rover Link

> An offline-first rover control, telemetry, autonomy, and learning stack built around an STM32 controller, Bluetooth, a Flutter mobile application, and an optional ML/backend toolchain.

[![Build Rover Link APK](https://github.com/D-engahmed/rover_link/actions/workflows/android-apk.yml/badge.svg)](https://github.com/D-engahmed/rover_link/actions/workflows/android-apk.yml)

Rover Link is a layered robotics project rather than a single application. The rover firmware owns sensors, actuators, and the final safety boundary. A Flutter Android application provides the operator interface, Bluetooth transport, telemetry visualization, deterministic phone-side navigation, command tracing, and local data collection. Offline Python tooling supports perception experiments, behavior cloning, and a separate reinforcement-learning experiment for person approach.

The repository intentionally distinguishes implemented behavior from migration designs and experiments.

## System at a glance

~~~text
                     ┌─────────────────────────────────────┐
                     │              Flutter                 │
                     │  operator UI • telemetry • commands  │
                     │  baseline autonomy • follow control  │
                     │  local JSONL data collection         │
                     └──────────────────┬──────────────────┘
                                        │ Bluetooth
                                        ▼
                     ┌─────────────────────────────────────┐
                     │               STM32                  │
                     │ command handling • sensors • motors │
                     │ servo/radar • display • buzzer      │
                     │ final forward-safety stop           │
                     └─────────────────────────────────────┘
                                        ▲
                                        │
                          HC-SR04 + servo │ motor driver

Optional / offline:
phone JSONL → ML collector → labels → training/evaluation
phone sessions → future backend → storage/sync/model metadata
rover_rl → simulated PPO person-approach experiment
~~~

## What exists today

| Area | Status | Current reality |
|---|---|---|
| STM32 firmware | Implemented | Motor driver, HC-SR04, servo sweep, Bluetooth, TFT/LED-matrix/buzzer, scheduler, local forward-safety checks |
| Flutter app | Implemented | Manual/Assisted/Autonomous/Follow Me UI, Bluetooth, telemetry, command tracing, local data collection |
| Phone autonomy | Implemented | Deterministic navigation in RoverAiService |
| Follow Me | Partial | Controller consumes target distance/angle, but no camera/vision service is present in the current tree |
| Offline ML | Implemented tooling | Collection, normalization, Random Forest perception baseline, behavior-cloning policy, evaluation |
| Framed protocol | Partial | CRC encoder and message definitions exist; active runtime still uses single-byte commands |
| STM32 execution ACK | Not active | Current main.c does not emit the documented ACK responses |
| PPO RL policy | Experimental | NumPy PPO simulation, evaluation plots, exported Dart inference |
| RL mobile integration | Not integrated | Exported Dart policy is standalone |
| Backend | Contract only | Schemas and API proposal, no running server |
| Production hardware validation | Required | Thresholds, timing, stopping distance, reset/fault behavior, and door mechanics need physical acceptance tests |

## Active command interface

The current Flutter-to-STM32 path writes exactly one command byte.

| Action | Wire byte | Firmware behavior |
|---|---:|---|
| Forward | W | Forward if ultrasonic safety allows |
| Backward | S | Reverse |
| Left | A | Turn left |
| Right | D | Turn right |
| Spin-left API | Q | Currently also calls the left-turn function |
| Spin-right API | E | Currently also calls the right-turn function |
| Stop | P | Stop |
| Manual mode | M | Enter MANUAL and stop |
| Phone autonomy | F | Enter PHONE_AUTONOMY and stop |
| Speed | 0–9 | 0 = 100%; 1–9 = 10–90% |
| Speed up/down | +/- | Change speed by 10% |

Do not append CR/LF to these command bytes. The current firmware consumes one byte at a time.

## Active telemetry

The STM32 emits newline-delimited JSON. A representative record is:

~~~json
{"timestamp_ms":0,"front_distance_cm":84,"ultrasonic_distance_cm":84,"ultrasonic_valid":1,"radar_angle_deg":93,"speed":50,"direction":"FORWARD","mode":"PHONE_AUTONOMY","sequence":12}
~~~

The current firmware uses timestamp_ms = 0. Flutter replaces a missing/zero timestamp with the local receive time.

The Flutter telemetry model additionally supports optional fields such as target_distance_cm, target_angle_deg, speed_cm_s, and rssi_dbm. Their presence in the model does not mean the current STM32 firmware emits them.

## Safety boundary

The intended safety hierarchy is:

~~~text
hardware / STM32 safety
        >
command admission
        >
autonomy policy
        >
operator convenience
~~~

The current firmware prevents forward motion when ultrasonic data is invalid or at/below the configured forward safety threshold and stops phone-autonomy after a command-age timeout.

The repository also contains a reusable APP/SAFETY module with explicit sensor-age and heartbeat checks. However, the active main.c still contains direct safety checks rather than using that module as the single runtime source of truth. That consolidation is a hardening task.

## Flutter application

The Flutter project lives in rover_link1/.

Main surfaces:

- Home — link state, live perception, mode selection
- Drive — manual motor controls
- Radar — radar/telemetry visualization
- AI Autopilot — deterministic on-device navigation observability
- Settings — Bluetooth scanning and connection
- Command Monitor — command lifecycle inspection
- Mode screen — dedicated Manual, Assisted, Autonomous, and Follow Me flows

The main navigation shell creates shared Bluetooth, command, telemetry, dataset, and AI services so screens do not compete over separate rover connections.

Entering Manual is deliberately serialized:

~~~text
stop phone controller
        ↓
send P
        ↓
send M
        ↓
show Manual Drive
~~~

That prevents an old AI/follow controller from racing the user's manual input during a mode transition.

## Current deterministic autonomy

RoverAiService is the active phone-side autonomous controller.

It consumes live telemetry, aggregates servo-scan distances into left/front/right clearance, scores candidate directions, and emits a short movement command.

Current thresholds in that service:

- emergency stop: 18 cm
- obstacle threshold: 45 cm
- Follow Me stop distance: 25 cm
- Follow Me desired distance: 60 cm
- Follow Me angle deadband: 12 degrees

A second BaselineNavigationService exists for the offline autonomy/data path and uses different thresholds. This is useful for experimentation but is not a good long-term source of truth. The project should consolidate these controllers before productionization.

## Follow Me

Follow Me requires:

- target_distance_cm
- target_angle_deg

The radar servo angle is not treated as target bearing.

The repository currently does not contain the referenced vision_service.dart or a camera/face-detection service. Therefore Follow Me should be described as a target-telemetry controller, not as a finished vision-based person-following system.

## Offline ML

The ml/ directory provides:

~~~text
telemetry JSONL
    ↓
normalization
    ↓
session-aware split
    ↓
training
    ↓
held-out evaluation
~~~

Two supervised paths exist:

1. Random Forest perception baseline.
2. Behavior-cloning control policy.

Both use recording-session grouping to reduce temporal/environment leakage.

The dataset documentation explicitly avoids claiming HC-SR04 material classification. Range is not a material spectrometer.

## Reinforcement learning

The rover_rl/ directory contains a separate compact PPO experiment for person approach.

Observation:

~~~text
person_present
bearing_fraction
size_fraction
facing_camera
obstacle_norm
~~~

Actions:

~~~text
FORWARD
LEFT
RIGHT
STOP
~~~

Network:

~~~text
5 → tanh(32) → tanh(32)
                    ├→ policy logits (4)
                    └→ value (1)
~~~

The recorded experiment in rover_rl/README.md reports approximately:

- 500 PPO iterations
- about 1M simulated environment steps
- 200 deterministic held-out episodes
- 73.5% success
- 1.5% collision
- 25% timeout

The first recorded policy was 53.5% success with 45.5% timeout. Reducing the simulated turn increment from 15 degrees to 8 degrees improved the held-out simulation result and exposed a close-range oscillation failure mode.

Those numbers are simulation results, not physical rover guarantees.

The exported Dart inference code is not wired into the current Flutter runtime.

## Backend

backend/ currently defines an asynchronous service boundary for:

- rover/session metadata
- telemetry ingestion
- detections
- dataset samples
- model/version metadata

The backend is not required for driving and is not currently a running server in this repository.

## Repository structure

~~~text
.
├── .github/workflows/         CI
├── Grad_Project/              STM32 firmware
├── backend/                   backend contract + schemas
├── docs/                      canonical documentation
├── ml/                        offline ML tooling
├── rover_link1/               Flutter application
├── rover_rl/                  PPO simulation/experiment
├── example_trajectory.png     RL evaluation figure
└── training_curves.png        RL training figure
~~~

## Getting started

### Flutter

Use Flutter stable 3.35.0 for the CI-equivalent toolchain.

~~~bash
cd rover_link1
flutter pub get
flutter analyze
flutter test
flutter build apk --release
~~~

The CI workflow runs analyze and a release APK build.

The current Android application ID is still com.example.rover_link1 and the release build currently uses the debug signing configuration. Both must be changed for a distribution-ready release.

### ML

~~~bash
cd ml
python -m venv .venv
~~~

Windows:

~~~bash
.venv\Scripts\activate
~~~

Linux/macOS:

~~~bash
source .venv/bin/activate
~~~

Then:

~~~bash
pip install -r requirements.txt
~~~

See docs/ML_DATA_PIPELINE.md.

### RL

~~~bash
cd rover_rl
python train.py
python evaluate.py
python export_dart.py
~~~

Note that the current script default and the historical 500-iteration experiment are different configurations.

## Documentation map

| Document | Purpose |
|---|---|
| docs/README.md | Documentation index |
| docs/ARCHITECTURE.md | End-to-end system boundaries |
| docs/HARDWARE_AND_FIRMWARE.md | Embedded stack and physical validation |
| docs/COMMUNICATION_PROTOCOL.md | Active raw protocol and framed migration |
| docs/FLUTTER_APP.md | Mobile application design |
| docs/AUTONOMY_AND_FOLLOW_ME.md | Navigation and target-follow control |
| docs/RL_AND_ON_DEVICE_MODEL.md | PPO experiment and mobile integration boundary |
| docs/ML_DATA_PIPELINE.md | Dataset, training, evaluation |
| docs/BACKEND.md | Backend contract |
| docs/TESTING_AND_VALIDATION.md | Software and physical acceptance |
| docs/KNOWN_LIMITATIONS.md | Explicit current gaps |
| docs/ROADMAP.md | Risk-ordered next steps |
| docs/DECISIONS.md | Architecture decisions |
| docs/LINKEDIN_POST.md | Public-facing project explanation |

Historical phase specifications remain in docs/phases/.

## Engineering boundaries

Rover Link intentionally does not claim:

- HC-SR04 material classification;
- Bluetooth RSSI as precise metric localization;
- Bluetooth write success as proof of MCU execution;
- simulation success as physical autonomy success;
- a framed protocol as active end-to-end behavior;
- the PPO export as the current Flutter controller.

Those distinctions are part of the engineering story.
