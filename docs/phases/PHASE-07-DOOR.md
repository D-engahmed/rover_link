# Phase 07 — Door actuator

The existing servo driver remains the hardware abstraction. This phase adds a semantic door controller so autonomy does not depend on raw servo angles.

Current defaults are placeholders and must be calibrated against the physically built mechanism.

Required next hardware validation: if the mechanism can stall or pinch, add a limit switch/current/position feedback mechanism. A bare servo command is not proof that the door physically reached the requested state.

Acceptance:
- autonomy can request OPEN/CLOSE without knowing servo angles;
- door state is explicit;
- mechanical angles are centralized and calibratable.
