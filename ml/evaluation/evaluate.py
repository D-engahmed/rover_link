"""Evaluate a saved Rover perception model on a held-out group split."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import joblib
import numpy as np
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import GroupShuffleSplit


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    artifact = joblib.load(args.model)
    features = artifact["features"]
    rows = [json.loads(line) for line in Path(args.dataset).read_text(encoding="utf-8").splitlines() if line.strip()]
    X = np.array([[r.get("features", {}).get(f, np.nan) for f in features] for r in rows], dtype=float)
    y = np.array([r["label"] for r in rows])
    groups = np.array([r.get("session_id", "unknown") for r in rows])

    if len(np.unique(groups)) < 2:
        raise SystemExit("Evaluation requires at least two recording sessions.")

    splitter = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    _, test_idx = next(splitter.split(X, y, groups))
    pred = artifact["model"].predict(X[test_idx])
    labels = sorted(set(y[test_idx]) | set(pred))

    report = classification_report(y[test_idx], pred, output_dict=True, zero_division=0)
    matrix = confusion_matrix(y[test_idx], pred, labels=labels).tolist()
    result = {
        "model_labels": artifact["labels"],
        "evaluation_labels": labels,
        "samples": int(len(test_idx)),
        "classification_report": report,
        "confusion_matrix": matrix,
        "warning": "Metrics are only meaningful when sessions represent independent real-world conditions.",
    }
    Path(args.output).write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
