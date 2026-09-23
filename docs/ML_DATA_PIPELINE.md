# ML and data pipeline

## Purpose

The ml/ directory is an offline experimentation toolchain. It is deliberately outside the real-time motor-control loop.

The phone is the first data-collection node. A backend is optional.

## End-to-end flow

~~~text
STM32 telemetry
      ↓ Bluetooth
Flutter
      ↓
local JSONL
      ↓
ml/collector
      ↓
normalized records
      ↓
labeling
      ↓
session-aware split
      ↓
training
      ↓
held-out evaluation
~~~

## Session-aware evaluation

Rows from one rover run are correlated by:

- environment;
- lighting;
- hardware state;
- nearby timestamps;
- trajectory.

A row-level random split can therefore leak information between train and test.

The current ML scripts use GroupShuffleSplit with session_id as the grouping variable.

## Dataset schema

ml/schema/sample.schema.json supports:

- timestamp_ms;
- session_id;
- sample_id;
- source;
- firmware_version;
- hardware_version;
- numeric feature objects;
- label;
- label_confidence;
- annotator;
- notes.

The schema is extensible so new sensor fields can be added without redesigning the whole record.

## Collection

ml/collector/collect.py normalizes common aliases into canonical names, adds a session ID, preserves metadata, and writes stable JSONL.

It can read from a file or stdin.

## Perception baseline

ml/training/train.py trains a Random Forest classifier using:

- front_distance_cm;
- left_distance_cm;
- right_distance_cm;
- rear_distance_cm;
- radar_angle_deg;
- target_distance_cm;
- target_angle_deg;
- target_confidence;
- rssi_dbm;
- speed_cm_s.

Missing numeric values are median-imputed.

Evaluation reports classification metrics and a confusion matrix.

## Behavior-cloning control

ml/training/train_policy.py trains an MLP classifier to imitate recorded actions.

Inputs include:

- front/left/right distance;
- target distance/angle;
- speed;
- RSSI;
- previous action.

The supervised policy action set is:

- STOP;
- FORWARD;
- LEFT;
- RIGHT;
- REVERSE.

This is distinct from the four-action PPO environment in rover_rl/.

## Label policy

Recommended labels:

- open_space;
- obstacle;
- human_candidate;
- vehicle_candidate;
- wall;
- unknown.

Labels must be justified by real ground truth.

### HC-SR04 boundary

HC-SR04 distance/echo timing is not equivalent to a direct material signature.

Therefore the pipeline must not present a classifier trained on distance features as reliable metal/wood/material identification without additional sensing evidence.

## Data collection campaign

A useful physical dataset should vary:

- target/obstacle distance;
- angle;
- environment;
- object orientation;
- rover speed;
- approach direction;
- sensor dropout/no-echo cases;
- communication conditions.

Keep complete sessions independent for final evaluation.

## Model lineage

For a reproducible experiment, record:

~~~text
dataset version
session IDs
firmware version
hardware version
feature list
model architecture
hyperparameters
training seed
split protocol
evaluation metrics
model artifact
~~~

The repository currently captures part of this through session IDs and saved artifacts; full experiment tracking is still a future improvement.

## Relationship to rover_rl/

ml/ studies supervised learning from recorded sessions.

rover_rl/ studies reinforcement learning in a controlled simulator.

Do not mix their metrics or call the PPO result a supervised-data result.
