# Dataset and labeling workflow

## Session identity

Every physical recording session should have a unique session_id.

Do not randomly split rows from the same physical run into train and test.

## Recommended labels

- open_space
- obstacle
- human_candidate
- vehicle_candidate
- wall
- unknown

Human/vehicle candidate labels require suitable ground truth.

## Example

~~~json
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
~~~

## Collection protocol

Vary:

- distance;
- angle;
- environment;
- object orientation;
- rover speed;
- approach direction;
- sensor/no-echo conditions.

Keep evaluation sessions independent.

## HC-SR04 limitation

An HC-SR04 distance reading is not a material signature. Do not convert the availability of ML tooling into a claim of metal/wood/material identification.

## Label quality

Preserve:

- annotator;
- confidence;
- notes;
- firmware version;
- hardware version.

When annotators disagree, retain that information instead of silently collapsing it.
