#ifndef DOOR_CONTROLLER_H
#define DOOR_CONTROLLER_H

typedef enum
{
    DOOR_CLOSED = 0,
    DOOR_OPENING,
    DOOR_OPEN,
    DOOR_CLOSING,
    DOOR_FAULT
} DoorState_t;

void DOOR_Init(void);
void DOOR_Open(void);
void DOOR_Close(void);
DoorState_t DOOR_GetState(void);

#endif
