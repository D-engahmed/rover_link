# Rover Link Backend

## Status

The backend is currently a service contract, not a running backend application.

It is intentionally outside the real-time motor-control loop.

## Responsibilities

- rover registration and session metadata;
- telemetry ingestion;
- target detections;
- navigation events;
- dataset sample storage;
- model/version metadata;
- future synchronization and experiment infrastructure.

## Non-responsibilities

The backend must not own:

- motor control;
- emergency stop;
- local safety;
- immediate navigation decisions.

The rover must remain able to stop safely without Internet access.

## Proposed API

~~~text
POST /api/v1/rovers/{rover_id}/sessions
POST /api/v1/rovers/{rover_id}/telemetry
POST /api/v1/rovers/{rover_id}/detections
POST /api/v1/datasets/samples
GET  /api/v1/models/current
~~~

These are proposed interfaces, not deployed endpoints.

## Schema boundary

See schemas/telemetry.schema.json.

The backend schema is richer than the current STM32 JSON stream, so future synchronization needs explicit mapping, validation, and schema versioning.

## Future implementation

A first backend can use FastAPI + PostgreSQL with authenticated rover/device identity, authenticated users, server-side validation, idempotent ingestion, offline upload queues, and model-artifact lineage.

Backend availability must never become a motor-control dependency.
