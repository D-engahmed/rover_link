#include "APP/DOOR/door_controller.h"
#include "HAL/SERVO/SERVO_interface.h"

/* Calibrate these against the actual built mechanism. */
#define DOOR_CLOSED_ANGLE 0U
#define DOOR_OPEN_ANGLE   120U

static DoorState_t g_state = DOOR_CLOSED;

void DOOR_Init(void)
{
    SERVO_Init();
    SERVO_SetAngle(DOOR_CLOSED_ANGLE);
    g_state = DOOR_CLOSED;
}

void DOOR_Open(void)
{
    g_state = DOOR_OPENING;
    SERVO_SetAngle(DOOR_OPEN_ANGLE);
    g_state = DOOR_OPEN;
}

void DOOR_Close(void)
{
    g_state = DOOR_CLOSING;
    SERVO_SetAngle(DOOR_CLOSED_ANGLE);
    g_state = DOOR_CLOSED;
}

DoorState_t DOOR_GetState(void)
{
    return g_state;
}
