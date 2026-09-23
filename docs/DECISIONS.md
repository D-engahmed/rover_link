# Engineering decisions

## 1. STM32 is the final safety authority

The phone is a high-level compute and control node. It is not a suitable sole safety authority because Android scheduling, process state, Bluetooth reliability, and application crashes are outside the rover's physical control boundary.

Therefore the MCU can stop or reject unsafe forward motion independently.

## 2. Offline-first operation

The rover must not require Internet access to move safely or stop safely.

The phone can collect data locally and the backend is an optional synchronization layer.

## 3. Closed-loop short commands

The baseline follows:

~~~text
sense → decide → move briefly → sense again
~~~

This is easier to reason about than a long open-loop sequence when sensor conditions can change rapidly.

## 4. HC-SR04 is range sensing, not material classification

The data supports distance reasoning.

It does not by itself justify arbitrary material labels.

Any classifier must be tied to appropriate ground truth and sensing evidence.

## 5. RSSI is coarse proximity evidence

RSSI can vary with environment, orientation, interference, and radio conditions.

Therefore it is not treated as exact meters.

True spatial localization should use a real ranging/localization mechanism or multimodal fusion.

## 6. Transport success is separate from execution success

The phone can know a Bluetooth write returned successfully.

It cannot know that the motor driver executed the requested action without a response from the rover.

Therefore SENT and EXECUTED are different states.

## 7. Keep learned policies behind safety

A neural policy may select an action, but it must not own hard safety decisions.

Safety is deterministic and independently testable.

## 8. Keep the RL experiment small

The PPO experiment uses a compact five-input network.

This makes direct Dart inference possible for the experiment and reduces runtime dependencies.

It does not imply that every future robotics model should use the same architecture.

## 9. Session-aware ML evaluation

Samples from one physical session are correlated.

Grouping evaluation by session is therefore preferred over random row splitting.

## 10. Document partial implementations

A protocol encoder is not a full protocol implementation.

A schema is not a backend.

An exported model is not an integrated controller.

A simulation score is not a physical benchmark.

The repository documentation should say exactly where an implementation boundary is.
