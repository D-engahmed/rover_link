# Hardware and firmware

## Hardware roles

| Component | Role |
|---|---|
| STM32F4-class MCU project | real-time control, sensors, scheduling, safety |
| Motor driver | wheel actuation |
| HC-SR04 | distance measurement |
| Servo | radar sweep and door mechanism support |
| Bluetooth module | phone ↔ MCU transport |
| TFT/ST7735 | local radar/display |
| LED matrix / STP | local scrolling status |
| Buzzer | alerts and mode feedback |

The exact electrical wiring and board variant must be validated against the physical build.

## Embedded structure

~~~text
Grad_Project/
├── include/
│   ├── HAL/
│   ├── MCAL/
│   ├── LIB/
│   └── OS_Scheduler/
├── src/
│   ├── APP/
│   │   ├── AUTONOMY/
│   │   ├── DOOR/
│   │   ├── LOCALIZATION/
│   │   ├── PROTOCOL/
│   │   ├── SAFETY/
│   │   └── TARGET/
│   └── peripheral/application C sources
└── system/
    └── MCU support / HAL
~~~

## Scheduled firmware tasks

main.c creates seven application tasks.

| Task | Nominal scheduler period | Job |
|---|---:|---|
| Buzzer | 30 | buzzer service |
| Control | 50 | Bluetooth commands + phone watchdog |
| Display | 10 | LED-matrix state |
| Telemetry | 100 | JSON telemetry |
| Radar | 50 | servo sweep + radar event |
| Ultrasonic | 50 | HC-SR04 read + safety stop |
| TFT radar | 100 | local radar rendering |

These numbers are scheduler units, not guaranteed milliseconds. Confirm scheduler timing before documenting them as wall-clock rates.

## Command handling

The active firmware accepts:

- M / m — MANUAL
- F / f — PHONE_AUTONOMY
- W / w — forward
- S / s — backward
- A / a — left
- D / d — right
- Q / q — currently another left turn
- E / e — currently another right turn
- P / p — stop
- 0..9 — speed
- + / - — speed step

Every mode transition stops the rover before changing the mode.

## Ultrasonic safety

ForwardAllowed() denies forward movement when:

- ultrasonic validity is false;
- distance is zero;
- distance is at or below SAFETY_STOP_DISTANCE_CM.

App_UltrasonicTask also calls StopRover() when a valid reading reaches that safety threshold.

The active main.c defines a 30 cm firmware stop threshold.

## Sensor-fault semantics

In the active firmware, a zero HC-SR04 result is treated as invalid/no echo and current distance is replaced with an out-of-range placeholder for telemetry. Forward movement is still blocked.

The reusable APP/SAFETY module provides a more explicit stale-sensor policy with a 250 ms sensor timeout. The active control loop does not yet use that module as the only safety decision source.

## Phone watchdog

Phone_Command_Age is reset whenever a Bluetooth command byte is received.

During PHONE_AUTONOMY it increments and stops the rover once it reaches the configured timeout threshold.

This is a command-age watchdog, not a formal heartbeat packet protocol.

## Radar

A single HC-SR04 is mounted behind a servo sweep. The servo moves approximately from 30 to 150 degrees.

The resulting data is a time series:

~~~text
angle → distance
~~~

It is not equivalent to three independent simultaneous range sensors.

## Telemetry

The active firmware sends:

- timestamp_ms
- front_distance_cm
- ultrasonic_distance_cm
- ultrasonic_valid
- radar_angle_deg
- speed
- direction
- mode
- sequence

Mode and radar events are sent as separate JSON lines.

The current MCU timestamp is 0, so the Flutter side supplies local receive time when necessary.

## Semantic APP modules

### SAFETY

Defines configurable obstacle, caution, sensor-age, and heartbeat policies.

### PROTOCOL

Defines the framed packet contract and CRC16 encoder.

### AUTONOMY

Defines semantic autonomy states and an observation/decision structure.

### TARGET

Validates target detections and confidence.

### LOCALIZATION

Maps RSSI to coarse proximity bands while keeping bearing separate.

### DOOR

Provides semantic OPEN/CLOSE operations over the servo layer.

These modules are useful architectural boundaries, but not every one is currently the active runtime implementation.

## Physical acceptance

Before claiming robust autonomy, validate:

- HC-SR04 electrical compatibility;
- real minimum stop distance at maximum speed;
- MCU reset/brownout motor behavior;
- sensor no-echo behavior;
- Bluetooth disconnect behavior;
- phone crash behavior;
- servo mechanical limits;
- door stall/pinch behavior;
- scheduler timing;
- repeated Manual ↔ Autonomy transitions.
