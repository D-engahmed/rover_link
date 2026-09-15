# Offline-first control learning

The rover must remain operational without a backend. The phone is the first compute/data-collection node; STM32 is the hardware and safety authority.

```text
Sensors → STM32 telemetry → Bluetooth → Phone
                                  ↓
                         baseline controller
                                  ↓
                           safety gate
                                  ↓
                           action → STM32
                                  ↓
                              motors

Phone also records state + action → JSONL → training
```

## Training strategy

1. Start with the deterministic baseline controller.
2. Drive controlled physical sessions.
3. Record sensor state and the baseline action on the phone.
4. Add human overrides/ground-truth labels when the baseline is wrong.
5. Train the learned policy using independent session-based splits.
6. Compare the learned policy with the baseline in unseen physical sessions.
7. Deploy the learned policy to the phone only after it passes offline and physical safety tests.
8. Keep the STM32 safety gate active; AI never bypasses hard obstacle/timeout/emergency-stop rules.

The backend is optional and used for synchronization, storage, training infrastructure, experiment tracking, and model distribution. It is not part of the real-time control loop.
