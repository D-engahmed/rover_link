# Phase 04 — Autonomous navigation

## Status: Partial / baseline implemented

Implemented:
- deterministic phone-side navigation;
- servo-scan aggregation;
- phone-autonomy mode;
- safety-aware forward movement;
- autonomous UI and traceability.

The embedded autonomy module exists as a separate contract, but the primary current phone runtime is RoverAiService.

Two baseline controllers currently use different thresholds. Consolidate them before productionization.
