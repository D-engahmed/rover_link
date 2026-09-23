# Known limitations

This document records the current boundaries that must not be hidden behind polished UI or ambitious terminology.

- The active control channel is still single-byte; the framed CRC protocol is a migration layer.
- Flutter SENT means the Bluetooth write completed, not that STM32 executed the command.
- The current main.c does not implement the end-to-end execution ACK loop.
- Safety thresholds and checks are duplicated across firmware, APP/SAFETY, RoverAiService, BaselineNavigationService, and Assisted UI.
- APP/SAFETY is not yet the only runtime safety source of truth.
- Follow Me has target-control logic, but the current Flutter tree has no camera/vision service.
- radar_angle_deg is servo scan direction, not automatically target_angle_deg.
- The documented 73.5% RL result is simulation-only.
- The exported PPO policy is not integrated into the current Flutter controller.
- The RL observation needs a real perception implementation before deployment.
- STM32 telemetry currently emits timestamp_ms = 0.
- The backend is a contract/schema, not a running service.
- Battery and RSSI are supported by the Flutter model but are not fully sourced by the active STM32 telemetry.
- Flutter Q/E are labeled as spin commands, while current firmware maps them to left/right turn functions.
- Android release signing still uses the debug signing configuration.
- Android application ID is still com.example.rover_link1.
- No LICENSE file is currently present.
- Physical stopping distance, reset behavior, sensor failure handling, and door mechanics require hardware validation.
- Two deterministic baseline controllers currently use different thresholds.
