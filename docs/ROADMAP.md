# Rover Link roadmap

This roadmap is ordered by system risk, not by visual feature count.

## P0 — Make the current control loop internally consistent

### Centralize safety

Use one canonical safety interface for forward-motion admission.

Inputs should include:

- distance validity;
- sensor age;
- obstacle distance;
- command heartbeat age.

The result should be explicit:

- CLEAR;
- CAUTION;
- STOP_SENSOR;
- STOP_LINK;
- STOP_OBSTACLE;
- STOP_INVALID_COMMAND.

Then remove competing threshold definitions.

### Resolve command semantics

Either implement real spin behavior for Q/E or rename the Flutter APIs.

### Make timestamps real

Replace the current firmware timestamp placeholder with a real monotonic/RTC-derived timestamp or clearly version the timestamp semantics.

## P1 — Finish communication

Migrate the active path from single-byte commands to:

~~~text
SOF | VERSION | TYPE | SEQUENCE | LENGTH | PAYLOAD | CRC16
~~~

Deliver:

- STM32 decoder;
- Flutter codec;
- length/CRC validation;
- sequence correlation;
- heartbeat message;
- command ACK;
- blocked/rejected reason;
- telemetry version;
- compatibility tests.

Keep the raw protocol as a controlled migration mode until the new path is proven.

## P1 — Make Follow Me a real perception system

Choose and implement a target source:

- phone camera;
- external camera;
- another localization sensor;
- deliberate external target telemetry.

Define a target contract with:

- type;
- confidence;
- distance;
- bearing;
- timestamp;
- future track ID.

Movement should require fresh, validated target evidence.

## P1 — Physical autonomy benchmark

Create repeatable test courses and scenarios.

Measure:

- successful approach;
- emergency stops;
- stop distance;
- collisions/near-collisions;
- timeouts;
- false-forward events;
- communication failures;
- mode-transition failures.

## P2 — Integrate learned control

Only after deterministic baseline behavior is stable:

~~~text
real perception
      ↓
feature normalization
      ↓
learned policy
      ↓
external safety gate
      ↓
command trace
      ↓
Bluetooth
      ↓
STM32 safety
~~~

Keep deterministic control available as the fallback.

## P2 — Implement backend

Build the documented API with:

- device identity;
- authentication;
- authorization;
- telemetry/session storage;
- dataset storage;
- offline upload queue;
- idempotent ingestion;
- model registry.

Do not make backend availability a motor-control dependency.

## P3 — Productionization

- change Android application ID;
- configure release signing;
- define license;
- document privacy/data retention;
- version the wire protocol;
- record hardware/firmware versions;
- add experiment tracking;
- add release artifacts and reproducibility metadata.

## Definition of done

Rover Link should not be described as production-ready until:

1. safety has one runtime source of truth;
2. active communication is versioned;
3. hardware command execution is ACK-confirmed;
4. sensor freshness is enforced;
5. Follow Me has a real target-perception source;
6. learned policy is evaluated on independent physical sessions;
7. backend failure cannot compromise local safety;
8. application packaging/signing is productionized.
