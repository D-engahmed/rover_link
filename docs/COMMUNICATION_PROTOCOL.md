# Communication protocol

Rover Link currently has two protocol layers: an active simple wire format and a designed framed protocol that is not yet the end-to-end runtime contract.

## Active phone-to-STM32 commands

Flutter writes one byte at a time:

~~~text
W = forward
S = backward
A = left
D = right
Q = left-turn alias
E = right-turn alias
P = stop
M = manual mode
F = phone autonomy
0..9 = speed
+/- = speed adjustment
~~~

The Flutter Bluetooth service intentionally does not append CR/LF. The STM32 command task consumes a byte at a time.

## Active telemetry

The STM32 emits newline-delimited JSON. A representative record:

~~~json
{"timestamp_ms":0,"front_distance_cm":84,"ultrasonic_distance_cm":84,"ultrasonic_valid":1,"radar_angle_deg":93,"speed":50,"direction":"FORWARD","mode":"PHONE_AUTONOMY","sequence":12}
~~~

The app also receives separate JSON event lines for mode changes and radar updates.

## Flutter normalization

RoverTelemetry.fromJson():

- uses ultrasonic_distance_cm as a fallback for front_distance_cm;
- uses radar_angle_deg as a fallback for target_angle_deg;
- replaces a zero/missing timestamp with phone receive time.

The last fallback is convenient for migration but semantically dangerous. Radar servo angle is not necessarily a target bearing.

## Framed protocol design

The STM32 APP/PROTOCOL module defines:

~~~text
SOF | VERSION | TYPE | SEQUENCE | LENGTH | PAYLOAD | CRC16
~~~

Current definitions:

| Field | Value/design |
|---|---|
| SOF | 0xAA |
| version | 1 |
| message type | HEARTBEAT / COMMAND / TELEMETRY / ACK / ERROR |
| sequence | 8-bit |
| length | payload length |
| payload | max 32 bytes |
| CRC16 | CRC-16/Modbus-style calculation |

The encoder calculates the CRC over version/type/sequence/length/payload and appends the CRC low/high bytes.

## What is not complete

The repository has the packet definitions and encoder, but the current end-to-end runtime still uses raw command bytes.

Before adopting the framed protocol as the production contract, implement:

1. STM32 decoder/parser;
2. Flutter encoder/decoder;
3. CRC rejection tests;
4. length validation;
5. sequence correlation;
6. heartbeat frames;
7. ACK and error semantics;
8. migration/backward compatibility;
9. integration tests.

## ACK and execution truth

The UI deliberately distinguishes:

~~~text
Bluetooth write success
        ≠
STM32 command execution
~~~

A future ACK flow should be sequence-correlated:

~~~text
Flutter → COMMAND(seq=12, W)
STM32   → ACK(seq=12, EXECUTED)
~~~

or:

~~~text
STM32 → ACK(seq=12, BLOCKED, reason=OBSTACLE)
~~~

Search and history show ACK design work, but the current main.c does not provide the complete execution-ACK loop. Therefore current documentation must not describe the rover as ACK-confirmed.

## Command semantics mismatch

Flutter names Q/E as spinLeft/spinRight. The current STM32 implementation calls the same left/right turn functions used by A/D.

Before claiming spin semantics, either implement an actual spin or rename those Flutter actions.

## Migration strategy

Do not change UI, controller, and wire protocol simultaneously.

Preferred order:

~~~text
packet specification
    ↓
STM32 parser
    ↓
Flutter codec
    ↓
sequence correlation
    ↓
ACK/error handling
    ↓
compatibility tests
    ↓
migrate commands incrementally
    ↓
remove raw-byte assumptions
~~~
