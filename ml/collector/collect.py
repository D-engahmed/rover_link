"""Collect Rover telemetry JSON into a stable JSONL training dataset.

Input is one JSON object per line. The collector extracts numeric sensor/navigation
features and preserves metadata needed for later grouping and evaluation.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
import uuid
from pathlib import Path

FEATURE_ALIASES = {
    "front_distance_cm": ("front_distance_cm", "front", "distance_cm"),
    "left_distance_cm": ("left_distance_cm", "left"),
    "right_distance_cm": ("right_distance_cm", "right"),
    "rear_distance_cm": ("rear_distance_cm", "rear"),
    "radar_angle_deg": ("radar_angle_deg", "radar_angle", "angle"),
    "target_distance_cm": ("target_distance_cm", "target_distance"),
    "target_angle_deg": ("target_angle_deg", "target_angle"),
    "target_confidence": ("target_confidence", "confidence"),
    "rssi_dbm": ("rssi_dbm", "rssi"),
    "speed_cm_s": ("speed_cm_s", "speed"),
}


def _first_number(obj: dict, keys: tuple[str, ...]):
    for key in keys:
        value = obj.get(key)
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            return float(value)
    return None


def normalize(raw: dict, session_id: str) -> dict:
    features = {}
    for canonical, aliases in FEATURE_ALIASES.items():
        value = _first_number(raw, aliases)
        if value is not None:
            features[canonical] = value

    # Preserve nested telemetry commonly emitted by rover protocols.
    nested = raw.get("telemetry")
    if isinstance(nested, dict):
        for canonical, aliases in FEATURE_ALIASES.items():
            if canonical not in features:
                value = _first_number(nested, aliases)
                if value is not None:
                    features[canonical] = value

    label = raw.get("label") or raw.get("target_type") or "unlabeled"
    timestamp = raw.get("timestamp_ms")
    if not isinstance(timestamp, int):
        timestamp = int(time.time() * 1000)

    return {
        "timestamp_ms": timestamp,
        "session_id": session_id,
        "sample_id": raw.get("sample_id", uuid.uuid4().hex),
        "source": raw.get("source", "stm32_telemetry"),
        "firmware_version": raw.get("firmware_version", "unknown"),
        "hardware_version": raw.get("hardware_version", "unknown"),
        "features": features,
        "label": str(label),
        "label_confidence": raw.get("label_confidence"),
        "annotator": raw.get("annotator", ""),
        "notes": raw.get("notes", ""),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", help="Input JSONL file. Omit to read stdin.")
    parser.add_argument("--output", required=True)
    parser.add_argument("--session-id", default=None)
    args = parser.parse_args()

    session_id = args.session_id or uuid.uuid4().hex
    source = open(args.input, "r", encoding="utf-8") if args.input else sys.stdin
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    count = 0
    with source, output.open("w", encoding="utf-8") as dst:
        for line_number, line in enumerate(source, 1):
            line = line.strip()
            if not line:
                continue
            try:
                raw = json.loads(line)
                if not isinstance(raw, dict):
                    raise ValueError("telemetry record must be a JSON object")
                record = normalize(raw, session_id)
                dst.write(json.dumps(record, separators=(",", ":")) + "\n")
                count += 1
            except (json.JSONDecodeError, ValueError) as exc:
                print(f"skip line {line_number}: {exc}", file=sys.stderr)

    print(f"wrote {count} samples to {output}")


if __name__ == "__main__":
    main()
