# Phase 07 — Door actuator

## Status: Partial / semantic controller

A semantic door controller exists above the servo HAL with explicit open/close states and centralized angles.

The complete autonomy door sequence is not yet wired end-to-end, and the commanded servo angle does not prove that the physical mechanism reached the desired state.
