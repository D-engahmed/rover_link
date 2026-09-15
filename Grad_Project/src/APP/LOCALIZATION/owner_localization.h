#ifndef OWNER_LOCALIZATION_H
#define OWNER_LOCALIZATION_H

#include "LIB/STD_TYPES.h"

typedef struct
{
    s16 bearing_deg;
    u8 proximity_level; /* 0 unknown, 1 far, 2 near, 3 very near */
    s8 rssi_dbm;
    u8 link_valid;
} OwnerLocalization_t;

/* RSSI is used as proximity/link evidence, not as meter-accurate ranging. */
OwnerLocalization_t OWNERLOCAL_Update(s8 rssi_dbm, u8 link_valid, s16 target_bearing_deg);

#endif
