"""Safety gate: AI or baseline may propose an action, but safety can override it."""
from __future__ import annotations
from .controller import Action, SensorState, ControllerConfig

def enforce(action: Action, state: SensorState, cfg: ControllerConfig = ControllerConfig()) -> Action:
    front = state.front_distance_cm
    if front is None or front <= cfg.emergency_stop_cm:
        return Action.STOP
    if action == Action.FORWARD and front <= cfg.obstacle_cm:
        return Action.STOP
    return action
