# Rover Link — on-device AI verification

## What the current app runs

The current Flutter AI Autopilot is the deterministic navigation baseline in RoverAiService. It is not the PPO model in rover_rl/.

~~~text
STM32 sensors
    ↓
Bluetooth telemetry
    ↓
RoverTelemetryService
    ↓
RoverAiService.decide()
    ↓
RoverCommandService
    ↓ Bluetooth
STM32
~~~

## Manual verification

1. Build and install the Android APK.
2. Pair the phone with the rover Bluetooth module.
3. Connect from Settings.
4. Wait for Bluetooth READY.
5. Open AI Autopilot.
6. Confirm the runtime label is the deterministic baseline.
7. Start AI.
8. Vary the ultrasonic obstacle distance.
9. Observe the AI decision and command trace.
10. Verify Bluetooth TX state.

## Meaning of SENT

SENT means the Flutter Bluetooth write completed.

It does not prove STM32 parsing, safety acceptance, or motor-driver execution.

Execution proof requires an STM32 acknowledgement path.

## Current thresholds

The phone-side AI uses an 18 cm emergency threshold and 45 cm obstacle threshold.

The active STM32 main.c uses a 30 cm forward safety threshold.

These values are not identical and should eventually be consolidated.

## RL boundary

The exported PPO Dart implementation is not connected to the current Flutter runtime.

Before integration:

- provide a real target-perception source;
- match training feature semantics exactly;
- test normalization;
- keep a deterministic safety veto outside the model;
- replay real telemetry;
- compare against baseline;
- validate physically at low speed.
