# Rover ML Pipeline

The ml/ directory contains offline collection, training, and evaluation tooling for Rover Link.

## Flow

telemetry -> Flutter local JSONL -> normalization -> session-aware split -> training -> held-out evaluation

## Components

- collector/collect.py: normalizes telemetry records and preserves session/model metadata.
- training/train.py: Random Forest perception baseline.
- training/train_policy.py: behavior-cloning control policy.
- evaluation/: held-out reports and confusion matrices.
- schema/: common sample schema.

## Evaluation rule

Samples from one physical recording session are correlated. The current training/evaluation scripts therefore group by session_id instead of randomly splitting individual rows.

## Sensing boundary

HC-SR04 supplies range/echo timing. It does not by itself justify arbitrary material classification. Any human/vehicle/material label needs suitable ground truth or additional sensing.

## Learning tracks

The supervised ML pipeline in ml/ is separate from the NumPy PPO experiment in rover_rl/.

For reproducibility, record dataset/session IDs, firmware/hardware versions, feature definitions, model configuration, seed, split protocol, metrics, and artifact.
