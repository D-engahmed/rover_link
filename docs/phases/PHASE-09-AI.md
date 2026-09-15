# Phase 09 — AI inference and learning loop

The AI contract is perception-first. Model output becomes evidence for target tracking/navigation; it is never an unrestricted motor command.

Training data must be synchronized across modalities and split by session/environment to avoid leakage. Model artifacts must be versioned and tied to the dataset/configuration used to produce them.

Initial target classes: unknown, human, vehicle, obstacle.

Acceptance:
- inference output validates against the schema;
- confidence is explicit;
- model version is traceable;
- false-positive/false-negative metrics are recorded;
- safety controller can reject any AI recommendation.
