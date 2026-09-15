# Rover approach RL model

PPO-trained policy for the actual driving decision in Follow Me mode:
given camera bearing/size (from `vision_service.dart`'s face detection) and
ultrasonic obstacle distance, output forward/left/right/stop — replacing
the hand-written gradient-search/face-centering rules that only ever
*displayed* a steering suggestion and never actually drove the rover
autonomously.

## What actually ran, with real numbers

Trained and evaluated in this sandbox (numpy only — see "Why numpy, not
torch/SB3" below). Not a claim, an actual run:

- 500 PPO iterations, ~1M environment steps, ~100 seconds wall-clock
- Held-out evaluation (200 episodes, seeds never used in training,
  deterministic policy — no exploration noise):
  - **Success: 73.5%** (reached the door-trigger condition: centered,
    facing, ≤1m)
  - **Collision: 1.5%**
  - **Timeout: 25%**

That 73.5% is with a bug found and fixed mid-session (see below), not the
first result. The first trained policy only hit 53.5% held-out — I'm
reporting both numbers because "73.5%" without that context would hide a
real methodological finding.

## The bug: close-range oscillation

First training run's failure episodes all showed the exact same pattern —
`LRLRLRLRLR...` forever. Diagnosis: turning 15° per `L`/`R` command causes
a *large* swing in apparent bearing when the rover is already close to the
person (small physical angle change → large angular swing at short range),
so the policy would overshoot the ±0.12 centering window on every single
turn — a limit cycle, not a training failure. Reducing `TURN_DEG` from 15°
to 8° in `env.py` and retraining measurably fixed most of it: held-out
success went 53.5% → 73.5%, timeouts dropped 45.5% → 25%.

**This matters for real hardware, not just the simulation:** if your
firmware's `L`/`R` commands turn the rover by a large fixed angle, the real
rover will hit the same oscillation near the person. Either make the
turn-per-command smaller, or give the firmware a way to do smaller
adjustment turns than a full `L`/`R` step — this is a real design
constraint the RL training surfaced, not a simulation quirk.

## The remaining 25% timeouts — two identified patterns, not fixed

Inspected the actual action sequences of failing episodes rather than just
reporting the percentage:
1. **Residual oscillation** — same cause as above, less frequent at 8°
   turns but not eliminated.
2. **Search failure at the frame edge** — when the person drifts near the
   edge of the camera's field of view while the rover is already very
   close, the policy spins slowly trying to recenter and sometimes doesn't
   make it before the episode/attempt times out.

Neither is fixed — flagging them as concrete next steps (finer turns still,
or adding a "back up" action using the `BACK`/`B` command that exists in
the real protocol but isn't in this model's 4-action space yet) rather than
quietly shipping a model with unexplained failures.

## Why numpy, not torch/stable-baselines3

The original plan was Stable-Baselines3 + PyTorch, matching
[[amma-attention-rl]]'s toolchain. `pip install torch` hit this sandbox's
disk quota partway through (torch's CUDA dependencies are multiple GB) and
there's no way around that from inside the sandbox — no access to a
CPU-only wheel index either. Given the observation space is 5 floats and
the action space is 4 discrete choices, a hand-rolled 2-layer MLP isn't
actually a downgrade — a network this small doesn't need a heavy autodiff
framework, and the payoff is that the trained weights export as plain
numbers (`export_dart.py` → `rover_policy_weights.dart`), so on-device
inference is direct matrix multiplication with zero new Flutter
dependencies, rather than a torch → ONNX → TFLite conversion pipeline
(another native package, another possible AGP/compileSdk fight after this
session's `bluetooth_classic` one).

If you specifically want this on SB3/PyTorch to match AMMA's architecture
more literally once you're off a disk-constrained machine, `env.py` is
already shaped like a gymnasium `Env` (`reset`/`step`/`observation_dim`/
`n_actions`) and needs only a thin wrapper class to plug into SB3 directly.

## Files

- `env.py` — the simulation (rover kinematics, camera bearing/size model,
  ultrasonic obstacle model, reward matching the real door-trigger logic
  exactly). Known sim-to-real gaps are documented in its docstring — no
  camera noise model, no occlusion, stationary person.
- `policy.py` — MLP actor-critic + PPO update, pure numpy, with a derived
  (not approximated) analytic gradient for the entropy bonus.
- `train.py` — training loop, saves `trained_policy.npz` +
  `training_history.json`.
- `evaluate.py` — held-out evaluation + `training_curves.png` +
  `example_trajectory.png`.
- `export_dart.py` — weights → `rover_policy_weights.dart`.
- `policy_inference.dart` — the Dart forward pass. **Not yet wired into
  RoverState** — see below.

## Integration into the Flutter app — not done yet, and one real decision needed

This model isn't plugged into `rover_link/` yet. Wiring it in means:

1. Copy `rover_policy_weights.dart` and `policy_inference.dart` into
   `rover_link/lib/services/`.
2. Add a periodic tick (e.g. every 300–500ms) while in Follow Me + camera
   mode that builds the 5-feature observation from `RoverState`'s current
   `lastSighting` and `nearestObstacleCm`, calls `runPolicy()`, and maps
   the resulting `RoverAction` to the same `drive()` calls manual mode
   already uses.
3. **The decision I haven't made for you:** the hard e-stop
   (`obstacleCriticalCm`) already overrides everything today, independent
   of mode — that has to stay true no matter what the RL policy outputs,
   since it's a safety rule, not a preference the model gets to override
   by being trained differently. But should the RL policy's action *always*
   run once it clears the e-stop check, or should there be a secondary
   sanity clamp (e.g., refuse consecutive identical turns past some count,
   directly addressing the oscillation failure mode above) before it
   reaches the motors? I'd default to adding that clamp, given the
   oscillation bug is real and measured, not hypothetical — but that's your
   call to confirm, not mine to silently decide.
