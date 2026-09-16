# Rover Link — On-Device AI Verification

## Runtime

The current rover navigation AI runs inside the Flutter Android application. It is not a backend request and does not require Internet access for inference.

```text
STM32 sensors
    ↓ Bluetooth telemetry
Flutter Android app
    ↓
RoverAiService
    ↓
navigation decision
    ↓
RoverCommandService
    ↓ Bluetooth write
STM32
```

The current implementation is a deterministic navigation baseline (`rover_navigation_policy_v0.1`), not a trained neural network. A trained mobile model can replace the decision function later without changing the UI/command trace contract.

## How to verify the output

1. Build/install the release APK.
2. Connect the phone to the rover Bluetooth device.
3. Open **AI Autopilot**.
4. Confirm `Bluetooth = READY`.
5. Press **START AI**.
6. Confirm `AI AUTOPILOT = RUNNING`.
7. Move an obstacle into/out of the ultrasonic field.
8. Watch **Current AI Output** for the decision and confidence.
9. Watch **AI → BLUETOOTH → STM32** for the last transmitted wire command and TX status.
10. Use **Command Monitor** to inspect the complete event sequence.

Expected example:

```text
AI output: FORWARD
Last AI TX: W\r\n
TX status: BLUETOOTH WRITE SUCCEEDED
```

With a close obstacle, the baseline should select `STOP` when the emergency threshold is reached.

## Command lifecycle

The app records:

```text
PROPOSED → APPROVED → QUEUED → SENT
```

or, when the Bluetooth write fails:

```text
PROPOSED → APPROVED → QUEUED → FAILED
```

The trace records source (`AI`, `HUMAN`, `SAFETY`, `SYSTEM`), wire command, timestamp, and TX latency where available.

## What SENT means

`SENT` means the Flutter app successfully completed the Bluetooth write. It does **not** prove that the STM32 executed the command.

An actual hardware acknowledgement requires an STM32 response protocol, for example:

```text
Flutter → W\r\n
STM32   → ACK W\r\n
```

No STM32 firmware change is included in this app-only verification PR.

## Training-model upgrade path

When training data and weights are ready, the intended production path is:

```text
sensor telemetry → preprocessing → mobile model inference → safety filter → command trace → Bluetooth → STM32
```

The model must be benchmarked on representative real sensor sequences before replacing the baseline controller.
