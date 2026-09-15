"""Offline deterministic rover controller used before learned-policy training."""
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum

class Action(str, Enum):
    FORWARD = "FORWARD"
    LEFT = "LEFT"
    RIGHT = "RIGHT"
    STOP = "STOP"

@dataclass(frozen=True)
class SensorState:
    front_distance_cm: float | None
    left_distance_cm: float | None
    right_distance_cm: float | None
    target_distance_cm: float | None = None
    target_angle_deg: float | None = None

@dataclass(frozen=True)
class ControllerConfig:
    emergency_stop_cm: float = 15.0
    obstacle_cm: float = 40.0
    preferred_clearance_cm: float = 70.0

def safe_distance(value: float | None, threshold: float) -> bool:
    return value is not None and value >= threshold

def decide(state: SensorState, cfg: ControllerConfig = ControllerConfig()) -> Action:
    front = state.front_distance_cm
    if front is None or front <= cfg.emergency_stop_cm:
        return Action.STOP
    if front > cfg.obstacle_cm:
        return Action.FORWARD

    left = state.left_distance_cm if state.left_distance_cm is not None else 0.0
    right = state.right_distance_cm if state.right_distance_cm is not None else 0.0
    if left <= cfg.emergency_stop_cm and right <= cfg.emergency_stop_cm:
        return Action.STOP
    return Action.LEFT if left > right else Action.RIGHT
