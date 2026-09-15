"""
RoverApproachEnv — a small 2D simulation of the actual task: find the
person (via simulated camera bearing/size, matching vision_service.dart's
output shape), avoid obstacles (via simulated ultrasonic, matching the
'+US:' distance signal), and reach the same door-trigger condition already
implemented in RoverState._maybeOpenDoor(): centered, facing, close enough.

Deliberately NOT a port of the AMMA delivery-robot environment — that task
(traffic-aware navigation to a waypoint, PPO + YOLOv8 + A*, Raspberry-Pi
delivery robot) is a different problem with different sensors. This is a
new, smaller environment shaped around what THIS rover (STM32 + HC-05 +
HC-SR04 + phone camera) actually has.

Known simplifications (sim-to-real gaps you should know about before
trusting this on real hardware):
- No camera image noise model — bearing/size are computed from exact
  geometry, not from an actual face-detector's failure modes.
- No obstacle occlusion of the camera's view of the person.
- Person is stationary and doesn't react to the rover.
- Ultrasonic is modeled as a single forward cone, not HC-SR04's real beam
  pattern.
"""
from __future__ import annotations
import numpy as np

# Action ids — match constants.dart exactly (F/L/R/S), so the trained
# policy's outputs map directly onto real drive commands with no
# translation layer to get wrong later.
FORWARD, LEFT, RIGHT, STOP = 0, 1, 2, 3
ACTION_NAMES = {FORWARD: "F", LEFT: "L", RIGHT: "R", STOP: "S"}

ARENA_SIZE = 6.0          # metres, square arena
CAMERA_FOV_HALF_DEG = 35  # matches a typical phone camera's usable half-FOV
CAMERA_MAX_RANGE = 5.0    # metres
OBSTACLE_CONE_HALF_DEG = 15
OBSTACLE_MAX_RANGE = 2.0  # metres — HC-SR04 realistic max reliable range
N_OBSTACLES = 4
OBSTACLE_RADIUS = 0.25

STEP_FORWARD_M = 0.15
TURN_DEG = 8  # was 15 — see README: 15° caused a close-range LRLRLR... limit cycle

# Mirrors constants.dart exactly — training against the same thresholds the
# app will actually use at inference/deployment time.
OBSTACLE_CRITICAL_CM = 25
DOOR_APPROACH_CM = 100
CENTERED_BEARING_THRESHOLD = 0.12
FACING_YAW_THRESHOLD_DEG = 20

MAX_STEPS = 200


def wrap_angle(a):
    return (a + np.pi) % (2 * np.pi) - np.pi


class RoverApproachEnv:
    """Plain reset()/step() interface (no gymnasium dependency — this
    sandbox is disk-constrained and torch/gymnasium/stable-baselines3
    wouldn't fit; the observation/action space is tiny enough that this
    doesn't need that machinery anyway)."""

    observation_dim = 5  # [person_present, bearing_frac, size_frac, facing_camera, obstacle_norm]
    n_actions = 4

    def __init__(self, seed: int | None = None):
        self.rng = np.random.default_rng(seed)
        self.reset()

    def reset(self):
        self.rover_pos = np.array([ARENA_SIZE / 2, 0.5])
        self.rover_heading = np.pi / 2  # facing "up" into the arena

        # Person placed somewhere reachable, not on top of the rover.
        angle = self.rng.uniform(0, 2 * np.pi)
        dist = self.rng.uniform(2.0, ARENA_SIZE / 2 - 0.5)
        self.person_pos = self.rover_pos + dist * np.array([np.cos(angle), np.sin(angle)])
        self.person_pos = np.clip(self.person_pos, 0.3, ARENA_SIZE - 0.3)

        # Which way the person is facing — fixed for the episode. The
        # rover has to end up roughly in front of them, not just close.
        self.person_facing = self.rng.uniform(0, 2 * np.pi)

        # Static circular obstacles, kept clear of the rover start and the
        # person themself.
        self.obstacles = []
        tries = 0
        while len(self.obstacles) < N_OBSTACLES and tries < 200:
            tries += 1
            p = self.rng.uniform(0.5, ARENA_SIZE - 0.5, size=2)
            if np.linalg.norm(p - self.rover_pos) < 0.8:
                continue
            if np.linalg.norm(p - self.person_pos) < 0.8:
                continue
            self.obstacles.append(p)
        self.obstacles = np.array(self.obstacles) if self.obstacles else np.zeros((0, 2))

        self.steps = 0
        self._prev_dist = np.linalg.norm(self.person_pos - self.rover_pos)
        return self._observe()

    def _observe(self):
        to_person = self.person_pos - self.rover_pos
        dist = np.linalg.norm(to_person)
        bearing = wrap_angle(np.arctan2(to_person[1], to_person[0]) - self.rover_heading)
        fov_half = np.radians(CAMERA_FOV_HALF_DEG)

        present = bool(abs(bearing) < fov_half and dist < CAMERA_MAX_RANGE)
        if present:
            bearing_frac = float(np.clip(bearing / fov_half, -1, 1))
            size_frac = float(np.clip(1 - dist / CAMERA_MAX_RANGE, 0, 1))
            # Facing check: is the person's fixed facing direction roughly
            # pointed back at the rover's current position?
            person_to_rover = wrap_angle(
                np.arctan2(self.rover_pos[1] - self.person_pos[1],
                           self.rover_pos[0] - self.person_pos[0])
                - self.person_facing
            )
            facing = float(abs(person_to_rover) < np.radians(FACING_YAW_THRESHOLD_DEG))
        else:
            bearing_frac, size_frac, facing = 0.0, 0.0, 0.0

        obstacle_norm = self._ultrasonic_norm()

        self._last_dist = dist
        self._last_bearing_frac = bearing_frac
        self._last_facing = facing
        return np.array([float(present), bearing_frac, size_frac, facing, obstacle_norm],
                         dtype=np.float32)

    def _ultrasonic_norm(self):
        """Nearest obstacle within a forward cone, normalized 0 (touching)
        .. 1 (clear beyond OBSTACLE_MAX_RANGE)."""
        if len(self.obstacles) == 0:
            return 1.0
        best = OBSTACLE_MAX_RANGE
        cone_half = np.radians(OBSTACLE_CONE_HALF_DEG)
        for obs in self.obstacles:
            to_obs = obs - self.rover_pos
            d = np.linalg.norm(to_obs) - OBSTACLE_RADIUS
            if d < 0:
                d = 0
            ang = wrap_angle(np.arctan2(to_obs[1], to_obs[0]) - self.rover_heading)
            if abs(ang) < cone_half and d < best:
                best = d
        return float(np.clip(best / OBSTACLE_MAX_RANGE, 0, 1))

    def step(self, action: int):
        self.steps += 1

        if action == FORWARD:
            self.rover_pos = self.rover_pos + STEP_FORWARD_M * np.array(
                [np.cos(self.rover_heading), np.sin(self.rover_heading)]
            )
            self.rover_pos = np.clip(self.rover_pos, 0.05, ARENA_SIZE - 0.05)
        elif action == LEFT:
            self.rover_heading = wrap_angle(self.rover_heading + np.radians(TURN_DEG))
        elif action == RIGHT:
            self.rover_heading = wrap_angle(self.rover_heading - np.radians(TURN_DEG))
        # STOP: no motion.

        obs = self._observe()
        obstacle_cm = self._last_obstacle_cm()

        reward = -0.01  # step penalty — rewards efficiency
        terminated = False
        info = {"result": None}

        # Progress shaping — closer is better, every step.
        reward += 2.0 * (self._prev_dist - self._last_dist)
        self._prev_dist = self._last_dist

        # Collision / critical-obstacle failure — mirrors the app's own
        # e-stop threshold. This is what the policy is trained to avoid;
        # it does NOT replace the real e-stop, which stays a hard rule in
        # the deployed app regardless of what this model outputs.
        if obstacle_cm < OBSTACLE_CRITICAL_CM:
            reward -= 5.0
            terminated = True
            info["result"] = "collision"

        # Success — exactly the real door-trigger condition.
        elif (
            self._last_bearing_frac is not None
            and abs(self._last_bearing_frac) < CENTERED_BEARING_THRESHOLD
            and self._last_facing >= 1.0
            and self._last_dist * 100 <= DOOR_APPROACH_CM
        ):
            reward += 10.0
            terminated = True
            info["result"] = "success"

        truncated = self.steps >= MAX_STEPS
        if truncated and not terminated:
            info["result"] = "timeout"

        return obs, reward, terminated, truncated, info

    def _last_obstacle_cm(self):
        return self._ultrasonic_norm() * OBSTACLE_MAX_RANGE * 100
