#include "APP/AUTONOMY/autonomy.h"
#include "APP/SAFETY/safety_policy.h"

AutonomyDecision_t AUTONOMY_Step(const AutonomyObservation_t *o)
{
    AutonomyDecision_t d = { AUTONOMY_FAULT, 0, 0 };
    if (o == 0) return d;

    if (o->front_cm == 0U || o->front_cm <= SAFETY_STOP_DISTANCE_CM)
    {
        d.state = AUTONOMY_SCANNING;
        d.steering = (o->left_cm > o->right_cm) ? -1 : 1;
        d.speed = 0;
        return d;
    }

    if (o->target_valid && o->target_distance_cm <= 120U)
    {
        d.state = (o->target_distance_cm <= 105U) ? AUTONOMY_ALIGNING_TARGET : AUTONOMY_APPROACHING_TARGET;
        d.steering = (o->target_angle_deg < -5) ? -1 : (o->target_angle_deg > 5 ? 1 : 0);
        d.speed = (o->target_distance_cm <= 105U) ? 0U : 35U;
        return d;
    }

    d.state = AUTONOMY_NAVIGATING;
    if (o->left_cm > o->right_cm && o->left_cm > 60U) d.steering = -1;
    else if (o->right_cm > 60U) d.steering = 1;
    else d.steering = 0;
    d.speed = 30U;
    return d;
}
