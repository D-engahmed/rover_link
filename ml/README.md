# Rover ML Pipeline

This directory contains the offline dataset, training, and evaluation pipeline for Rover Link perception experiments.

## Important scope

The current HC-SR04 hardware reports echo-derived distance. It does **not** expose the raw acoustic waveform required to claim reliable material classification. The pipeline therefore supports labels such as `obstacle`, `human_candidate`, `wall`, `vehicle`, etc. only when those labels are backed by appropriate ground truth. Do not interpret a trained classifier as material identification unless the sensor hardware provides sufficient information.

## Layout

```text
ml/
├── README.md
├── requirements.txt
├── schema/
│   └── sample.schema.json
├── data/
│   ├── raw/.gitkeep
│   ├── labeled/.gitkeep
│   ├── splits/.gitkeep
│   └── README.md
├── collector/
│   ├── __init__.py
│   └── collect.py
├── training/
│   ├── __init__.py
│   └── train.py
├── evaluation/
│   ├── __init__.py
│   └── evaluate.py
└── models/.gitkeep
```

## Dataset flow

```text
STM32 telemetry JSONL
        ↓
collector / raw recorder
        ↓
JSONL samples
        ↓
manual or assisted labels
        ↓
labeled dataset
        ↓
group-aware train/validation/test split
        ↓
model training
        ↓
evaluation + confusion matrix
        ↓
versioned model artifact
```

The split is group-aware so samples from one recording session are not randomly leaked across train and test sets.

## Quick start

```bash
cd ml
python -m venv .venv
# Windows: .venv\\Scripts\\activate
# Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt

python collector/collect.py --input telemetry.jsonl --output data/raw/session.jsonl
python training/train.py --input data/labeled/dataset.jsonl --output models/rover_perception.joblib
python evaluation/evaluate.py --dataset data/labeled/dataset.jsonl --model models/rover_perception.joblib --output evaluation_report.json
```

For the first hardware run, the collector can also read stdin:

```bash
python collector/collect.py --output data/raw/session.jsonl
```

Paste one telemetry JSON object per line and press Enter. Stop with Ctrl+C.
