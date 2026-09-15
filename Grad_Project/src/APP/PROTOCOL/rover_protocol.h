#ifndef ROVER_PROTOCOL_H
#define ROVER_PROTOCOL_H

#include "LIB/STD_TYPES.h"

#define ROVER_PROTOCOL_SOF 0xAAU
#define ROVER_PROTOCOL_VERSION 1U
#define ROVER_PROTOCOL_MAX_PAYLOAD 32U

typedef enum
{
    ROVER_MSG_HEARTBEAT = 1,
    ROVER_MSG_COMMAND = 2,
    ROVER_MSG_TELEMETRY = 3,
    ROVER_MSG_ACK = 4,
    ROVER_MSG_ERROR = 5
} RoverMessageType_t;

typedef enum
{
    ROVER_CMD_STOP = 0,
    ROVER_CMD_FORWARD,
    ROVER_CMD_BACKWARD,
    ROVER_CMD_LEFT,
    ROVER_CMD_RIGHT,
    ROVER_CMD_MANUAL,
    ROVER_CMD_AUTONOMOUS,
    ROVER_CMD_DOOR_OPEN,
    ROVER_CMD_DOOR_CLOSE
} RoverCommand_t;

typedef struct
{
    u8 version;
    u8 type;
    u8 sequence;
    u8 length;
    u8 payload[ROVER_PROTOCOL_MAX_PAYLOAD];
    u16 crc;
} RoverPacket_t;

u16 ROVER_PROTOCOL_Crc16(const u8 *data, u16 length);
u8 ROVER_PROTOCOL_Encode(const RoverPacket_t *packet, u8 *out, u16 out_capacity);

#endif
