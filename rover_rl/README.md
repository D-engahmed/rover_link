# Rover approach RL model

## Scope

This directory contains a compact reinforcement-learning experiment for a simulated person-approach problem.

It is a research artifact, not the current Flutter controller.

## What the environment models

The simulator is a small 2D task with:

- a rover;
- a person target;
- static obstacles;
- simplified camera-derived bearing/size;
- simplified ultrasonic obstacle range;
- a close/facing/centered success condition.

It is intentionally shaped around this rover rather than copied from a general robotics benchmark.

## Observation space

The policy receives exactly five values:

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

## Model

~~~text
5 → tanh(32) → tanh(32)
                    ├→ policy logits (4)
                    └→ value (1)
~~~

PPO is implemented directly in NumPy with Adam, GAE-lambda, clipping, entropy regularization, and manual backpropagation.

## Recorded experiment

The repository records a run with:

- 500 PPO iterations;
- about 1M simulated environment steps;
- 200 deterministic held-out episodes;
- 73.5% success;
- 1.5% collision;
- 25% timeout.

The first recorded run reached 53.5% success and 45.5% timeout.

A close-range L/R oscillation was traced to a 15 degree turn increment. Reducing the simulated turn increment to 8 degrees and retraining produced the documented improvement to 73.5% success and 25% timeout.

These are simulation metrics only.

## Known failure modes

The remaining timeout bucket in the documented experiment includes:

- residual close-range oscillation;
- loss of the target near the edge of the modeled camera field.

The environment does not fully model real camera noise, occlusion, person motion, ultrasonic beam behavior, rover dynamics, motor lag, battery variation, or communication loss.

## Training reproducibility

The current train.py default is 150 iterations × 2048 steps, about 307k steps.

The documented 500-iteration result was therefore produced with a different training configuration and should be treated as a recorded experiment, not an automatic consequence of the current default.

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

The exported Dart implementation performs direct matrix math and deterministic argmax selection.

## Flutter integration status

The exported model is not wired into rover_link1.

A safe integration needs:

1. a real target-perception source;
2. exact feature/normalization compatibility;
3. replay tests on real telemetry;
4. an external safety veto;
5. deterministic action mapping;
6. physical low-speed validation.

Do not describe the simulation result as real-rover autonomy accuracy.
