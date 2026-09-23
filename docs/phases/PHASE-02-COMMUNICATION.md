# Phase 02 — Rover communication

## Status: Partial / migration layer

The repository defines a framed protocol:

~~~text
SOF | VERSION | TYPE | SEQUENCE | LENGTH | PAYLOAD | CRC16
~~~

It includes typed message/command enums and a CRC16 encoder.

The active runtime is still one-byte commands plus newline-delimited JSON telemetry. A complete migration needs a decoder, sequence correlation, heartbeat frames, ACK/error handling, and compatibility tests.
