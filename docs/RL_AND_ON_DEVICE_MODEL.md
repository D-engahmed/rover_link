# RL and on-device model

## Scope

rover_rl/ is a separate reinforcement-learning experiment for a small person-approach problem.

It is not the controller currently executed by RoverAiService.

## Environment

The simulation is a 2D rover/person/obstacle task.

The target is considered reached when the rover is:

- close enough;
- centered on the target;
- approximately facing the person;
- not in a critical obstacle state.

This is intentionally smaller than a general navigation benchmark.

## Observation space

The policy sees five values:

~~~text
person_present
bearing_fraction
size_fraction
facing_camera
obstacle_norm
~~~

## Action space

~~~text
0 → FORWARD
1 → LEFT
2 → RIGHT
3 → STOP
~~~

## Network

~~~text
5 → tanh(32) → tanh(32)
                    ├→ policy logits (4)
                    └→ value (1)
~~~

The PPO implementation is NumPy-only and contains Adam, GAE-lambda, PPO clipping, entropy regularization, and manual backpropagation.

## Recorded result

The current rover_rl documentation records an experiment with:

- 500 PPO iterations;
- about 1M environment steps;
- 200 deterministic held-out episodes;
- 73.5% success;
- 1.5% collision;
- 25% timeout.

The first recorded run reached 53.5% success and 45.5% timeout.

A close-range oscillation was identified. A 15° simulated turn increment produced repeated left/right overshoot; reducing that increment to 8° improved the reported held-out result.

These figures are simulation evidence only.

## Reproducibility detail

The present train.py default is 150 iterations × 2048 steps per iteration, about 307k steps. The recorded 500-iteration result therefore came from a different run configuration and should not be treated as the default script output without verifying/reproducing it.

## Export

~~~text
trained_policy.npz
       ↓
export_dart.py
       ↓
rover_policy_weights.dart
       +
policy_inference.dart
~~~

The exported Dart implementation uses direct matrix multiplication and deterministic argmax action selection.

## Why direct Dart inference

The model is tiny. A direct implementation avoids adding a model-runtime dependency and avoids a Torch → ONNX → TFLite conversion path for this experiment.

That is an engineering tradeoff, not a claim that direct matrix math is always better for larger models.

## Integration status

The exported policy is not currently wired into rover_link1.

Before integration, the system needs:

- a real target/perception source;
- feature semantics that exactly match training;
- normalization tests;
- external safety veto;
- replay tests on real telemetry;
- baseline comparison;
- physical low-speed validation.

## Sim-to-real gaps

The simulator simplifies:

- camera noise;
- occlusion;
- target motion;
- ultrasonic beam behavior;
- rover kinematics;
- motor lag;
- battery effects;
- communication loss.

A successful simulation episode is therefore not equivalent to a successful physical run.
