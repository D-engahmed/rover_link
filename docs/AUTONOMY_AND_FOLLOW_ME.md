# Autonomy and Follow Me

## 1. Active autonomous controller

The current Flutter "AI" runtime is a deterministic policy in RoverAiService. It is not the PPO model under rover_rl/.

Control loop:

~~~text
STM32 telemetry
      ↓
RoverTelemetry
      ↓
RoverAiService.decide()
      ↓
RoverCommandService
      ↓ Bluetooth
STM32
      ↓
motors
~~~

## 2. Deterministic navigation

RoverAiService keeps scan-derived left/front/right clearances and scores them.

Current service constants:

| Parameter | Value |
|---|---:|
| AI emergency stop | 18 cm |
| obstacle threshold | 45 cm |
| Follow Me stop | 25 cm |
| Follow Me desired distance | 60 cm |
| Follow Me angle deadband | 12° |

The forward score is suppressed near obstacles. Side scores are reduced near obstacles. If the controller has no meaningful action, it stops.

This is a short closed-loop policy, not a global map planner:

~~~text
sense → decide → short command → sense again
~~~

## 3. Second baseline implementation

BaselineNavigationService is another deterministic implementation used by the offline autonomy/data path.

Its defaults differ:

- emergency stop: 15 cm;
- obstacle threshold: 40 cm;
- center region: 80–100°;
- side clearance smoothing;
- preferred clearance: 70 cm in the corresponding Python baseline configuration.

This split is acceptable for experimentation but not ideal for production. A single canonical controller/safety configuration should replace the duplicated threshold sets.

## 4. Follow Me

Follow Me consumes:

- target_distance_cm;
- target_angle_deg.

Decision logic:

~~~text
distance ≤ 25 cm     → STOP
angle < -12°         → LEFT
angle > +12°         → RIGHT
distance > 60 cm     → FORWARD
otherwise            → STOP
~~~

The controller will not move when target distance or target angle is unavailable.

## 5. Target semantics

Two quantities must remain separate:

- radar_angle_deg — where the servo/ultrasonic scan is pointed;
- target_angle_deg — estimated bearing of the target.

The current Flutter model permits a fallback from target_angle_deg to radar_angle_deg, which is a migration convenience but should not be used as evidence of person localization.

## 6. Perception status

The architecture contains target contracts and confidence validation, but the current Flutter repository does not contain the referenced vision_service.dart or a camera/face-detection implementation.

Therefore the current Follow Me capability is best described as:

> a phone-side controller that consumes target telemetry.

It should not be described as a finished camera-based human-following system.

## 7. Embedded autonomy contract

The STM32 APP/AUTONOMY module defines semantic states:

- parked;
- scanning;
- leaving park;
- navigating;
- approaching target;
- aligning target;
- door sequence;
- complete;
- fault.

Its observation includes front/left/right distance and target angle/distance/validity.

This is an application-layer contract. The current phone-autonomy runtime still primarily uses RoverAiService.

## 8. Safety interaction

Correct deployment order:

~~~text
navigation policy
      ↓
safety/admission
      ↓
Bluetooth
      ↓
STM32 safety
      ↓
motors
~~~

A learned policy should never be the final arbiter of a hard obstacle or watchdog stop.

## 9. Next autonomy milestone

Before adding a larger model:

1. consolidate baseline controllers;
2. centralize thresholds;
3. add sensor freshness;
4. add real target perception;
5. add command execution ACKs;
6. replay real sessions;
7. validate physically at low speed;
8. put a learned policy behind the same safety gate.
