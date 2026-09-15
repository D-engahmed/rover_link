#ifndef TARGET_H
#define TARGET_H

#include "LIB/STD_TYPES.h"

typedef enum
{
    TARGET_UNKNOWN = 0,
    TARGET_HUMAN,
    TARGET_VEHICLE,
    TARGET_OBSTACLE
} TargetType_t;

typedef struct
{
    TargetType_t type;
    u8 valid;
    u8 confidence_percent;
    u16 distance_cm;
    s16 angle_deg;
    u32 timestamp_ms;
} TargetDetection_t;

/* HC-SR04 measurements alone must not produce a material/class label. */
u8 TARGET_IsUsable(const TargetDetection_t *d);

#endif
