#include "APP/PROTOCOL/rover_protocol.h"

u16 ROVER_PROTOCOL_Crc16(const u8 *data, u16 length)
{
    u16 crc = 0xFFFFU;
    u16 i;
    u8 bit;

    for (i = 0U; i < length; i++)
    {
        crc ^= data[i];
        for (bit = 0U; bit < 8U; bit++)
        {
            if (crc & 1U) crc = (crc >> 1U) ^ 0xA001U;
            else crc >>= 1U;
        }
    }
    return crc;
}

u8 ROVER_PROTOCOL_Encode(const RoverPacket_t *packet, u8 *out, u16 out_capacity)
{
    u16 i;
    u16 crc;
    u16 required;

    if (packet == 0 || out == 0 || packet->length > ROVER_PROTOCOL_MAX_PAYLOAD)
        return 0U;

    required = (u16)(6U + packet->length);
    if (out_capacity < required) return 0U;

    out[0] = ROVER_PROTOCOL_SOF;
    out[1] = packet->version;
    out[2] = packet->type;
    out[3] = packet->sequence;
    out[4] = packet->length;
    for (i = 0U; i < packet->length; i++) out[5U + i] = packet->payload[i];

    crc = ROVER_PROTOCOL_Crc16(&out[1], (u16)(4U + packet->length));
    out[5U + packet->length] = (u8)(crc & 0xFFU);
    out[6U + packet->length - 1U] = (u8)(crc >> 8U);

    return (u8)required;
}
