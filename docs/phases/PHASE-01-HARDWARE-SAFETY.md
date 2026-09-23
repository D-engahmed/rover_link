# Phase 01 — Hardware safety

## Status: Partial

Implemented in the repository:
- STM32 forward-motion safety checks;
- invalid/zero ultrasonic handling;
- phone-autonomy command-age watchdog;
- reusable APP/SAFETY policy functions for obstacle, sensor-age, and heartbeat decisions.

The remaining architectural issue is that main.c still contains direct safety checks rather than using APP/SAFETY as the one runtime source of truth.

Physical validation remains required: electrical compatibility, real stopping distance, reset behavior, sensor-fault behavior, and actuator safety.
