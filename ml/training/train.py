"""Train a baseline perception classifier from Rover JSONL telemetry."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.metrics import classification_report
from sklearn.model_selection import GroupShuffleSplit
from sklearn.pipeline import Pipeline

FEATURES = [
    "front_distance_cm", "left_distance_cm", "right_distance_cm", "rear_distance_cm",
    "radar_angle_deg", "target_distance_cm", "target_angle_deg", "target_confidence",
    "rssi_dbm", "speed_cm_s",
]


def load(path: str):
    rows = [json.loads(line) for line in Path(path).read_text(encoding="utf-8").splitlines() if line.strip()]
    X = np.array([[r.get("features", {}).get(f, np.nan) for f in FEATURES] for r in rows], dtype=float)
    y = np.array([r["label"] for r in rows])
    groups = np.array([r.get("session_id", "unknown") for r in rows])
    return X, y, groups


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--test-size", type=float, default=0.2)
    args = parser.parse_args()

    X, y, groups = load(args.input)
    if len(np.unique(y)) < 2:
        raise SystemExit("Need at least two labels before training.")
    if len(np.unique(groups)) < 2:
        raise SystemExit("Need at least two recording sessions for a leakage-safe split.")

    splitter = GroupShuffleSplit(n_splits=1, test_size=args.test_size, random_state=42)
    train_idx, test_idx = next(splitter.split(X, y, groups))

    model = Pipeline([
        ("imputer", SimpleImputer(strategy="median")),
        ("classifier", RandomForestClassifier(n_estimators=300, random_state=42, class_weight="balanced")),
    ])
    model.fit(X[train_idx], y[train_idx])
    pred = model.predict(X[test_idx])

    report = classification_report(y[test_idx], pred, output_dict=True, zero_division=0)
    artifact = {
        "model": model,
        "features": FEATURES,
        "labels": sorted(np.unique(y).tolist()),
        "metrics": report,
        "train_samples": int(len(train_idx)),
        "test_samples": int(len(test_idx)),
    }
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(artifact, output)
    print(json.dumps(report, indent=2))
    print(f"saved {output}")


if __name__ == "__main__":
    main()
