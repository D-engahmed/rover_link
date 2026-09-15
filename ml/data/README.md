# Dataset and labeling workflow

Each recording session gets a unique `session_id`. Never randomly split rows from the same physical run across train and test; that creates temporal/environment leakage.

## Recommended labels

Start with labels that the available sensors can actually support:

- `open_space`
- `obstacle`
- `human_candidate` — only when ground truth comes from a human observer or an additional human-detection sensor
- `vehicle_candidate`
- `wall`
- `unknown`

Do **not** label `metal`, `wood`, etc. as if an HC-SR04 alone can reliably identify material. Add a sensor capable of providing material-discriminative information first.

## Label record

A labeled sample is JSONL:

```json
{
  "timestamp_ms": 1760000000000,
  "session_id": "session-001",
  "sample_id": "sample-0001",
  "features": {
    "front_distance_cm": 84.2,
    "left_distance_cm": 120.0,
    "right_distance_cm": 95.1,
    "radar_angle_deg": 90.0,
    "rssi_dbm": -67
  },
  "label": "obstacle",
  "label_confidence": 1.0,
  "annotator": "human",
  "notes": "foam box at 84 cm"
}
```

Collect multiple sessions for every label. Vary distance, angle, environment, object orientation, and rover speed. Keep a test session completely separate from training sessions.
