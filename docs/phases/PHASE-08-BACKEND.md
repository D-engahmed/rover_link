# Phase 08 — Backend telemetry and datasets

Backend storage is deliberately outside the real-time control loop.

STM32 remains capable of safe autonomous operation when Internet/backend connectivity is unavailable. Flutter synchronizes telemetry to the backend when connected.

Stored domains: rover, session, telemetry, detections, navigation events, dataset samples, and model versions.

Acceptance:
- telemetry conforms to a versioned schema;
- backend outage does not create a motor-control dependency;
- training data can be linked back to a rover/session/time window;
- model versions are traceable.
