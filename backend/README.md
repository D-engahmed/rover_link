# Rover Link Backend

The backend is an asynchronous telemetry and dataset service. It is not part of the real-time motor-control loop.

## Responsibilities
- rover registration and session metadata;
- telemetry ingestion and storage;
- target detections and navigation events;
- dataset collection for later model training;
- model/version metadata.

## Non-responsibilities
- direct GPIO/motor control;
- emergency-stop decisions;
- replacing STM32 local safety.

## Proposed API
- `POST /api/v1/rovers/{rover_id}/sessions`
- `POST /api/v1/rovers/{rover_id}/telemetry`
- `POST /api/v1/rovers/{rover_id}/detections`
- `POST /api/v1/datasets/samples`
- `GET /api/v1/models/current`

The first implementation can use FastAPI + PostgreSQL. Authentication and deployment are intentionally left to the integration PR rather than embedded in firmware.
