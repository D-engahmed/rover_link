# Phase 01 — Hardware correctness and safety

## Goal
Establish deterministic safety boundaries before autonomous navigation or AI is allowed to command motion.

## Implemented
- Central safety thresholds for obstacle, sensor freshness, and Bluetooth heartbeat.
- Explicit safety decisions instead of treating a missing ultrasonic echo as a valid distance.
- Safety policy kept independent from motor and UI code.

## Existing hardware retained
- STM32 motor driver.
- HC-SR04 ultrasonic sensor.
- Servo PWM door actuator.
- Bluetooth module over USART.
- TFT, buzzer, and existing scheduler.

## Required hardware validation
- Confirm HC-SR04 voltage-level compatibility with the exact STM32 board.
- Measure real minimum stopping distance under the rover's maximum speed.
- Verify motor driver fail-safe state after MCU reset.
- Verify servo mechanical open/close limits.

## Important limitation
A standard HC-SR04 reports echo timing/distance; it does not provide the raw acoustic waveform required for defensible material classification such as human/metal/wood. Object-type recognition therefore remains a later sensor-fusion/AI phase.

## Acceptance criteria
- Invalid/stale ultrasonic data cannot authorize motion.
- A stale communication heartbeat causes a safe stop.
- Obstacle distance at or below the configured stop threshold causes a safe stop.
