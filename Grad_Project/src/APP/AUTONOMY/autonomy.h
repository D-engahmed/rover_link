#ifndef AUTONOMY_H
#define AUTONOMY_H

#include "LIB/STD_TYPES.h"

typedef enum
{
    AUTONOMY_PARKED = 0,
    AUTONOMY_SCANNING,
    AUTONOMY_LEAVING_PARK,
    AUTONOMY_NAVIGATING,
    AUTONOMY_APPROACHING_TARGET,
    AUTONOMY_ALIGNING_TARGET,
    AUTONOMY_DOOR_SEQUENCE,
    AUTONOMY_COMPLETE,
    AUTONOMY_FAULT
} AutonomyState_t;

typedef struct
{
    u16 front_cm;
    u16 left_cm;
    u16 right_cm;
    s16 target_angle_deg;
    u16 target_distance_cm;
    u8 target_valid;
} AutonomyObservation_t;

typedef struct
{
    AutonomyState_t state;
    s8 steering;
    u8 speed;
} AutonomyDecision_t;

AutonomyDecision_t AUTONOMY_Step(const AutonomyObservation_t *observation);

#endif
