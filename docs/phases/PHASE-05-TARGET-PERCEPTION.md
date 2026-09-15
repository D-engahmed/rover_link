# Phase 05 — Target perception

Defines a target-detection contract suitable for sensor fusion.

Important engineering boundary: HC-SR04 provides distance/echo timing, not a raw acoustic signature. Therefore this layer does not fabricate material classes. Human/vehicle recognition should come from a camera or another sensor capable of producing class evidence, then be fused with ultrasonic range and bearing.

Acceptance:
- target detections have type, confidence, distance, angle, and timestamp;
- low-confidence detections are rejected;
- target information is an input to navigation, never a direct motor command.
