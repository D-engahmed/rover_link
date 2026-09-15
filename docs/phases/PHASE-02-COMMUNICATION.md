# Phase 02 — Rover communication protocol

Replace single-character motor commands with a framed protocol while keeping the legacy command service available during migration.

Frame:

`SOF | VERSION | TYPE | SEQUENCE | LENGTH | PAYLOAD | CRC16`

The protocol supports heartbeat, command, telemetry, ACK, and error messages.

## Acceptance criteria
- Corrupt frames are rejected by CRC.
- Every command can be correlated using a sequence number.
- Telemetry is structured and machine-readable.
- A heartbeat is available for link supervision.
- Legacy W/S/A/D/P commands can be mapped to the new command enum during transition.
