# Backend

## Current status

backend/ is currently a service contract, not a running backend application.

It contains:

- backend README/documentation;
- telemetry schema;
- proposed API boundaries.

## Intended responsibilities

The backend is for asynchronous:

- rover registration;
- session metadata;
- telemetry ingestion;
- target detections;
- navigation events;
- dataset samples;
- model/version metadata;
- future synchronization and experiment infrastructure.

## What it must not do

The backend must not be required for:

- motor control;
- emergency stop;
- local safety;
- immediate autonomous movement decisions.

The rover should remain capable of a safe local stop when the Internet or backend is unavailable.

## Proposed API

~~~text
POST /api/v1/rovers/{rover_id}/sessions
POST /api/v1/rovers/{rover_id}/telemetry
POST /api/v1/rovers/{rover_id}/detections
POST /api/v1/datasets/samples
GET  /api/v1/models/current
~~~

These paths are design proposals, not deployed endpoints.

## Telemetry schema

backend/schemas/telemetry.schema.json expects a richer contract than the current STM32 telemetry stream, including fields such as:

- rover_id;
- timestamp_ms;
- mode;
- front/left/right distance;
- battery_percent;
- target type/confidence/distance/angle.

A future synchronization layer therefore needs explicit field mapping and schema/version validation.

## Recommended implementation boundary

~~~text
rover + phone
      ↓
local operation
      ↓
offline queue
      ↓
backend synchronization
      ↓
persistent storage
      ↓
training / experiment / model metadata
~~~

The queue should handle offline operation, retries, duplicates, and schema evolution.

## Security requirements

A real service should add:

- authenticated rover/device identity;
- authenticated users;
- authorization per rover;
- TLS;
- server-side validation;
- rate limiting;
- auditability;
- model-artifact integrity;
- retention policies.

A public telemetry endpoint should not be assumed safe simply because the rover is a prototype.
