#include "APP/TARGET/target.h"

u8 TARGET_IsUsable(const TargetDetection_t *d)
{
    if (d == 0 || d->valid == 0U) return 0U;
    if (d->confidence_percent < 60U) return 0U;
    if (d->distance_cm == 0U) return 0U;
    return 1U;
}
