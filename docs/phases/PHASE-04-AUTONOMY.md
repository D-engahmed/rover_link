# Phase 04 — Autonomous obstacle avoidance

Introduces a deterministic autonomy state contract and local navigation baseline. The AI is not allowed to bypass the safety layer.

Inputs: front/left/right obstacle distances and an optional target bearing/distance.

Outputs: state, steering intent, and speed request.

The baseline intentionally uses short closed-loop decisions: sense → decide → move briefly → sense again.

Acceptance: stale/invalid sensor data stops the rover; near obstacles stop the rover; clear-space steering chooses the safer side; target approach stops at the configured alignment/approach boundary.
