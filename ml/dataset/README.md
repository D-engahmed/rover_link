# Offline-first control learning

The phone is the first compute and data-collection node. The STM32 remains the hardware and safety authority.

~~~text
Sensors
   ↓
STM32 telemetry
   ↓ Bluetooth
Phone
   ↓
baseline controller
   ↓
safety boundary
   ↓
action → STM32
   ↓
motors

Phone also records:
state + action → JSONL → training
~~~

## Training strategy

1. Start with the deterministic baseline.
2. Run controlled physical sessions.
3. Record telemetry and actions.
4. Add human corrections where the baseline is wrong.
5. Split by independent session.
6. Train the learned controller.
7. Compare it with the baseline on unseen sessions.
8. Validate the learned policy offline before physical actuation.
9. Keep STM32 safety active regardless of the learned model.

## Backend

The backend is optional for synchronization, storage, experiment infrastructure, and model distribution.

It is not part of the real-time control loop.

## Current implementation

The repository contains phone JSONL recording, supervised ML tooling, and a separate PPO simulation. The PPO model is not currently integrated into Flutter.
