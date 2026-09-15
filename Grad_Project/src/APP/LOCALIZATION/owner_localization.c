#include "APP/LOCALIZATION/owner_localization.h"

OwnerLocalization_t OWNERLOCAL_Update(s8 rssi_dbm, u8 link_valid, s16 target_bearing_deg)
{
    OwnerLocalization_t result;
    result.rssi_dbm = rssi_dbm;
    result.link_valid = link_valid;
    result.bearing_deg = target_bearing_deg;
    result.proximity_level = 0U;

    if (!link_valid) return result;

    /* Initial calibration bands; these are deliberately configurable and must be measured on the target BT module. */
    if (rssi_dbm >= -55) result.proximity_level = 3U;
    else if (rssi_dbm >= -70) result.proximity_level = 2U;
    else if (rssi_dbm >= -85) result.proximity_level = 1U;

    return result;
}
