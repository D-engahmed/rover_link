# Phone control integration

## Current runtime

~~~text
HC-SR04 + servo
      ↓
    STM32
      ↓ Bluetooth telemetry
    Flutter
      ↓
phone-side controller
      ↓
command byte
      ↓ Bluetooth
    STM32
      ↓
safety + motor driver
      ↓
motors
~~~

The backend is not required for driving.

## STM32 safety authority

The active firmware:

- blocks forward motion when ultrasonic data is invalid;
- stops at/below its configured forward safety threshold;
- stops phone-autonomy after the command-age watchdog expires.

The APP/SAFETY module has explicit sensor-age and heartbeat policy functions, but main.c does not yet route every safety decision through that module.

## Telemetry

Current STM32 telemetry is newline-delimited JSON.

The Flutter application normalizes it into RoverTelemetry.

## One ultrasonic sensor

There is one HC-SR04. The servo creates an angle/distance time series.

The phone can aggregate those scans into approximate side clearances. It is not equivalent to simultaneous left/front/right sensors.

## Follow Me

Follow Me expects target_distance_cm and target_angle_deg.

The radar servo angle is not a substitute for target bearing.

The current repository does not contain a camera/vision service, so target recognition is an unfinished input boundary.

## Protocol status

The active control path is one-byte commands.

The framed CRC protocol is a migration component, not yet the end-to-end runtime protocol.
