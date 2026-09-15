# Phase 03 — Flutter ↔ rover integration

The Flutter application already has Bluetooth scanning/connection and a command service. This phase adds a typed rover state boundary and a telemetry parser so UI code does not directly interpret raw Bluetooth strings.

## Target flow
BluetoothService → protocol adapter → telemetry parser → RoverState → screens.

## Required production work
- Replace polling-style UI state with a single connection/session controller.
- Add reconnect and heartbeat supervision.
- Expose RSSI as connection quality/proximity evidence, not precise distance.
- Add an emergency-stop action available from every driving screen.

## Acceptance criteria
- Manual driving remains available after migration.
- UI can display connection, battery, motion, sensor, and target state from one typed model.
- Bluetooth disconnect transitions the rover state to disconnected/reconnecting.
