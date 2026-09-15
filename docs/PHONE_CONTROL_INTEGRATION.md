# Phone control integration

## Runtime

```text
HC-SR04 + servo
      ↓
    STM32
      ↓ Bluetooth
    Flutter
      ↓
 baseline_v1
      ↓
 safety-aware command
      ↓ Bluetooth
    STM32
      ↓
    motors
```

The backend is not required for driving. The phone records JSONL locally and can upload it later for training.

## STM32 safety authority

- Forward commands are rejected when the latest ultrasonic reading is at or below `SAFETY_STOP_DISTANCE_CM`.
- Phone-autonomy mode stops after the command heartbeat expires.
- An ultrasonic read of zero is treated as no echo/clear for telemetry, but this should be replaced with an explicit sensor-fault state in the next hardware revision.

## Telemetry

The STM32 emits JSON Lines such as:

```json
{"timestamp_ms":0,"front_distance_cm":84,"radar_angle_deg":93,"mode":"PHONE_AUTONOMY"}
```

The phone replaces a zero/missing timestamp with its local receive timestamp.

## Current hardware limitation

There is one HC-SR04. The phone therefore receives a time series of `(angle, distance)` measurements while the servo scans. It does not receive independent left/right ultrasonic sensors. The baseline controller aggregates the scan into left/right clearance estimates before choosing a turn.

This is a navigation baseline, not a material/object classifier.
