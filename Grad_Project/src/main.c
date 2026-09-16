#include "LIB/STD_TYPES.h"
#include "LIB/UTILS.h"
#include "MCAL/RCC/MRCC_interface.h"
#include "MCAL/GPIO/GPIO_interface.h"
#include "MCAL/TIM/TIM_interface.h"
#include "MCAL/USART/USART_interface.h"
#include "MCAL/SPI/SPI_interface.h"
#include "HAL/MOTOR_DRIVER/MOTOR_DRIVER_interface.h"
#include "HAL/BTM/BTM_interface.h"
#include "HAL/ULTRASONIC/ULTRASONIC_interface.h"
#include "HAL/SERVO/SERVO_interface.h"
#include "HAL/BUZZER/BUZZER_interface.h"
#include "HAL/STP/STP_interface.h"
#include "HAL/TFT/ST7735_interface.h"
#include "OS_Scheduler/OS_interface.h"
#include "APP/SAFETY/safety_policy.h"

#define MODE_MANUAL_BT 1
#define MODE_PHONE_AUTONOMY 2
#define DIR_STOP_LED 0
#define DIR_FORWARD 1
#define DIR_BACKWARD 2
#define DIR_LEFT 3
#define DIR_RIGHT 4
#define PHONE_HEARTBEAT_TIMEOUT_TICKS 20U

u8 Current_Mode = MODE_MANUAL_BT;
u8 Current_Direction = DIR_STOP_LED;
u8 Robot_Speed = 50;
u16 Current_Distance = 400;
u8 Servo_Pos = 90;
s8 Servo_Direction = 3;
static u8 Phone_Command_Age = PHONE_HEARTBEAT_TIMEOUT_TICKS;
static u8 DisplayFrame[8];
static u16 Command_Sequence = 0;
static u16 Telemetry_Sequence = 0;

void Buzzer_OS_Task(void)
{
    BUZZER_Task();
}

static void StopRover(void)
{
    MOTOR_SHIELD_Stop();
    Current_Direction = DIR_STOP_LED;
}

static u8 ForwardAllowed(void)
{
    if (Current_Distance == 0 || Current_Distance <= SAFETY_STOP_DISTANCE_CM)
    {
        StopRover();
        BUZZER_PlayAlert();
        return 0;
    }
    return 1;
}

static void SendCommandAck(u8 command, u8 status, u8 reason)
{
    BTM_SendString((u8 *)"{\"event\":\"ack\",\"seq\":");
    BTM_SendNumber(Command_Sequence);
    BTM_SendString((u8 *)",\"command\":\"");

    switch (command)
    {
        case 'F': case 'f': BTM_SendString((u8 *)"F"); break;
        case 'M': case 'm': BTM_SendString((u8 *)"M"); break;
        case 'W': case 'w': BTM_SendString((u8 *)"W"); break;
        case 'S': case 's': BTM_SendString((u8 *)"S"); break;
        case 'A': case 'a': BTM_SendString((u8 *)"A"); break;
        case 'D': case 'd': BTM_SendString((u8 *)"D"); break;
        case 'Q': case 'q': BTM_SendString((u8 *)"Q"); break;
        case 'E': case 'e': BTM_SendString((u8 *)"E"); break;
        case 'P': case 'p': BTM_SendString((u8 *)"P"); break;
        case '+': BTM_SendString((u8 *)"+"); break;
        case '-': BTM_SendString((u8 *)"-"); break;
        default: BTM_SendString((u8 *)"UNKNOWN"); break;
    }

    BTM_SendString((u8 *)"\",\"status\":\"");

    if (status == 1)
    {
        BTM_SendString((u8 *)"EXECUTED");
    }
    else if (status == 2)
    {
        BTM_SendString((u8 *)"BLOCKED");
    }
    else
    {
        BTM_SendString((u8 *)"REJECTED");
    }

    BTM_SendString((u8 *)"\"");

    if (reason == 1)
    {
        BTM_SendString((u8 *)",\"reason\":\"OBSTACLE\"");
    }
    else if (reason == 2)
    {
        BTM_SendString((u8 *)",\"reason\":\"UNKNOWN_COMMAND\"");
    }

    BTM_SendString((u8 *)"}\r\n");
}

static void SendModeEvent(void)
{
    BTM_SendString((u8 *)"{\"event\":\"mode\",\"mode\":\"");

    if (Current_Mode == MODE_PHONE_AUTONOMY)
    {
        BTM_SendString((u8 *)"PHONE_AUTONOMY");
    }
    else
    {
        BTM_SendString((u8 *)"MANUAL");
    }

    BTM_SendString((u8 *)"\"}\r\n");
}

void App_ControlTask(void)
{
    u8 data;
    u8 speed_changed = 0;

    if (BTM_IsDataAvailable())
    {
        data = BTM_ReceiveData();
        Phone_Command_Age = 0;
        Command_Sequence++;

        if (data == 'F' || data == 'f')
        {
            Current_Mode = MODE_PHONE_AUTONOMY;
            StopRover();
            BUZZER_PlayStartup();
            SendModeEvent();
            SendCommandAck(data, 1, 0);
            return;
        }

        if (data == 'M' || data == 'm')
        {
            Current_Mode = MODE_MANUAL_BT;
            StopRover();
            BUZZER_PlayModeSwitch();
            SendModeEvent();
            SendCommandAck(data, 1, 0);
            return;
        }

        if (data >= '0' && data <= '9')
        {
            Robot_Speed = (data == '0') ? 100 : (data - '0') * 10;
            speed_changed = 1;
        }

        switch (data)
        {
            case 'W': case 'w':
                if (ForwardAllowed())
                {
                    MOTOR_SHIELD_MoveForward(Robot_Speed);
                    Current_Direction = DIR_FORWARD;
                    SendCommandAck(data, 1, 0);
                }
                else
                {
                    SendCommandAck(data, 2, 1);
                }
                break;

            case 'S': case 's':
                MOTOR_SHIELD_MoveBackward(Robot_Speed);
                Current_Direction = DIR_BACKWARD;
                BUZZER_PlayReversing();
                SendCommandAck(data, 1, 0);
                break;

            case 'A': case 'a':
                MOTOR_SHIELD_TurnLeft(Robot_Speed);
                Current_Direction = DIR_LEFT;
                SendCommandAck(data, 1, 0);
                break;

            case 'D': case 'd':
                MOTOR_SHIELD_TurnRight(Robot_Speed);
                Current_Direction = DIR_RIGHT;
                SendCommandAck(data, 1, 0);
                break;

            case 'Q': case 'q':
                MOTOR_SHIELD_TurnLeft(Robot_Speed);
                Current_Direction = DIR_LEFT;
                SendCommandAck(data, 1, 0);
                break;

            case 'E': case 'e':
                MOTOR_SHIELD_TurnRight(Robot_Speed);
                Current_Direction = DIR_RIGHT;
                SendCommandAck(data, 1, 0);
                break;

            case 'P': case 'p':
                StopRover();
                SendCommandAck(data, 1, 0);
                break;

            case '+':
                if (Robot_Speed <= 90) Robot_Speed += 10;
                speed_changed = 1;
                break;

            case '-':
                if (Robot_Speed >= 10) Robot_Speed -= 10;
                speed_changed = 1;
                break;

            default:
                SendCommandAck(data, 0, 2);
                break;
        }

        if (speed_changed && Current_Direction != DIR_STOP_LED)
        {
            if (Current_Direction == DIR_FORWARD && !ForwardAllowed())
            {
                SendCommandAck(data, 2, 1);
                return;
            }

            if (Current_Direction == DIR_FORWARD)
            {
                MOTOR_SHIELD_MoveForward(Robot_Speed);
            }
            else if (Current_Direction == DIR_BACKWARD)
            {
                MOTOR_SHIELD_MoveBackward(Robot_Speed);
            }
            else if (Current_Direction == DIR_LEFT)
            {
                MOTOR_SHIELD_TurnLeft(Robot_Speed);
            }
            else if (Current_Direction == DIR_RIGHT)
            {
                MOTOR_SHIELD_TurnRight(Robot_Speed);
            }

            SendCommandAck(data, 1, 0);
        }
        else if (speed_changed)
        {
            SendCommandAck(data, 1, 0);
        }
    }

    if (Current_Mode == MODE_PHONE_AUTONOMY)
    {
        if (Phone_Command_Age < PHONE_HEARTBEAT_TIMEOUT_TICKS)
        {
            Phone_Command_Age++;
        }

        if (Phone_Command_Age >= PHONE_HEARTBEAT_TIMEOUT_TICKS)
        {
            StopRover();
        }
    }
}

void App_SensorTask(void)
{
    Current_Distance = ULTRASONIC_GetDistance();
    if (Current_Distance == 0) Current_Distance = 400;

    if (Current_Mode == MODE_PHONE_AUTONOMY && Current_Distance <= SAFETY_STOP_DISTANCE_CM)
    {
        StopRover();
    }
}

void App_RadarTask(void)
{
    Servo_Pos += Servo_Direction;
    if (Servo_Pos >= 150 || Servo_Pos <= 30) Servo_Direction = -Servo_Direction;
    SERVO_SetAngle(Servo_Pos);
}

void App_TelemetryTask(void)
{
    Telemetry_Sequence++;

    BTM_SendString((u8 *)"{\"timestamp_ms\":0");
    BTM_SendString((u8 *)",\"front_distance_cm\":");
    BTM_SendNumber(Current_Distance);
    BTM_SendString((u8 *)",\"ultrasonic_distance_cm\":");
    BTM_SendNumber(Current_Distance);
    BTM_SendString((u8 *)",\"radar_angle_deg\":");
    BTM_SendNumber(Servo_Pos);
    BTM_SendString((u8 *)",\"speed\":");
    BTM_SendNumber(Robot_Speed);
    BTM_SendString((u8 *)",\"direction\":\"");

    switch (Current_Direction)
    {
        case DIR_FORWARD:
            BTM_SendString((u8 *)"FORWARD");
            break;
        case DIR_BACKWARD:
            BTM_SendString((u8 *)"BACKWARD");
            break;
        case DIR_LEFT:
            BTM_SendString((u8 *)"LEFT");
            break;
        case DIR_RIGHT:
            BTM_SendString((u8 *)"RIGHT");
            break;
        default:
            BTM_SendString((u8 *)"STOP");
            break;
    }

    BTM_SendString((u8 *)"\",\"mode\":\"");

    if (Current_Mode == MODE_PHONE_AUTONOMY)
    {
        BTM_SendString((u8 *)"PHONE_AUTONOMY");
    }
    else
    {
        BTM_SendString((u8 *)"MANUAL");
    }

    BTM_SendString((u8 *)"\",\"sequence\":");
    BTM_SendNumber(Telemetry_Sequence);
    BTM_SendString((u8 *)"}\r\n");
}

void App_DisplayTask(void)
{
    /* Keep the existing LED matrix/TFT ownership unchanged. */
    if (Current_Direction == DIR_STOP_LED)
    {
        for (u8 i = 0; i < 8; i++) DisplayFrame[i] = 0;
    }
}

int main(void)
{
    MRCC_init();
    MRCC_EN_peripheral_CLK(AHB1_BUS, GPIOA_EN);
    MRCC_EN_peripheral_CLK(AHB1_BUS, GPIOB_EN);
    MRCC_EN_peripheral_CLK(APB1_BUS, APB1_TIM2);
    MRCC_EN_peripheral_CLK(APB1_BUS, APB1_TIM4);
    MRCC_EN_peripheral_CLK(APB1_BUS, APB1_TIM3);
    MRCC_EN_peripheral_CLK(APB2_BUS, APB2_USART1);
    MRCC_EN_peripheral_CLK(APB2_BUS, APB2_SPI1);
    MRCC_EN_peripheral_CLK(APB2_BUS, APB2_TIM1);

    BUZZER_Init();
    BTM_Init();
    MOTOR_SHIELD_Init();
    TIM_PWM_Init(TIM2);
    ULTRASONIC_Init();
    SERVO_Init();
    SERVO_SetAngle(90);
    STP_Init();
    STP_StartAutoRefresh(DisplayFrame, 8);
    ST7735_Init();

    BTM_SendString((u8 *)"{\"event\":\"ready\",\"mode\":\"MANUAL\"}\r\n");
    BUZZER_PlayStartup();

    OS_CreateTask(0, 30, Buzzer_OS_Task, 0);
    OS_CreateTask(1, 50, App_ControlTask, 5);
    OS_CreateTask(2, 50, App_SensorTask, 10);
    OS_CreateTask(3, 50, App_RadarTask, 15);
    OS_CreateTask(4, 100, App_TelemetryTask, 20);
    OS_CreateTask(5, 50, App_DisplayTask, 25);

    Start_OS();

    while (1)
    {
        OS_Update();
    }
}
