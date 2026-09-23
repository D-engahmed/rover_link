# Rover Link architecture

## 1. System principle

Rover Link is organized around a hard boundary:

> High-level software may propose movement, but the STM32 remains the final local safety authority.

The phone is the UI, orchestration, telemetry, control-policy, and data-collection node. The backend is storage/synchronization infrastructure. Neither should be required for a safe stop.

## 2. Runtime layers

~~~text
Hardware
  ↓
MCAL
  ↓
HAL
  ↓
STM32 application modules + scheduler
  ↓ Bluetooth
Flutter transport and typed state
  ↓
controller / UI / dataset collection

Optional offline path:
recorded sessions → ML/RL tooling → evaluation

Optional future path:
phone → backend sync → storage / experiments / model metadata
~~~

### STM32

The embedded project contains MCAL, HAL, and APP layers.

APP modules include:

- SAFETY
- PROTOCOL
- AUTONOMY
- TARGET
- LOCALIZATION
- DOOR

Several modules are semantic contracts that are not yet the sole implementation used by main.c.

### Bluetooth

The active control channel is one byte per command.

The active telemetry channel is newline-delimited JSON.

A framed CRC protocol exists as a migration layer.

### Flutter

The main navigation shell creates shared service instances:

- BluetoothService
- RoverCommandService
- RoverTelemetryService
- RoverDatasetService
- RoverAiService

This avoids one screen accidentally becoming the owner of the Bluetooth transport.

## 3. Data and control flow

### Movement

~~~text
human or controller
      ↓
command service
      ↓
Bluetooth write
      ↓
STM32 command handler
      ↓
STM32 safety checks
      ↓
motor driver
~~~

### Telemetry

~~~text
HC-SR04 + servo + firmware state
      ↓
STM32 telemetry JSON
      ↓
Bluetooth
      ↓
RoverTelemetryService
      ↓
RoverTelemetry
      ├→ UI
      ├→ autonomy
      └→ local dataset
~~~

## 4. Manual transition

The application explicitly serializes the manual transition:

~~~text
stop phone controller
      ↓
send P
      ↓
send M
      ↓
make Drive screen authoritative
~~~

The ordering exists to avoid command races.

## 5. Safety hierarchy

The design target is:

~~~text
hardware safety
      >
safety admission
      >
navigation policy
      >
UI
~~~

The current repository contains safety logic at multiple layers, which is useful during development but creates threshold/configuration drift. Consolidation is required before claiming one canonical safety policy.

## 6. Command provenance

CommandTrace records:

- HUMAN
- AI
- SAFETY
- SYSTEM

and lifecycle stages:

~~~text
PROPOSED → APPROVED → QUEUED → SENT
                         └────→ FAILED

BLOCKED is a supported trace state for rejected actions.
~~~

The trace is observability, not execution proof.

## 7. Execution truth

The current meaning of SENT is:

> the Flutter Bluetooth write completed.

It is not:

> the STM32 executed the command.

The repository contains a design for ACK messages, but the active main.c does not complete that acknowledgement loop.

## 8. Learning boundary

The learning stack is separate from hard safety:

~~~text
recorded state/action
        ↓
training/evaluation
        ↓
learned policy
        ↓
external safety admission
        ↓
Bluetooth
        ↓
STM32 safety
~~~

This keeps the model from becoming the safety authority.

## 9. Architectural gaps

The current system still needs:

1. one canonical safety implementation;
2. full framed-protocol migration;
3. real execution ACKs;
4. an actual target-perception source for Follow Me;
5. learned-model integration behind the same safety interface;
6. a running backend if remote storage is needed;
7. complete reconnect/session supervision;
8. production release packaging/signing.
