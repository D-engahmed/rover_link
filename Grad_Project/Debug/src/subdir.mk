################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/BTM_program.c \
../src/BUZZER_program.c \
../src/EXTI_program.c \
../src/GPIO_program.c \
../src/IR_REMOTE_program.c \
../src/LEDMATRIX_program.c \
../src/MOTOR_DRIVER_program.c \
../src/MRCC_program.c \
../src/NVIC_program.c \
../src/OS_program.c \
../src/SERVO_program.c \
../src/SPI_program.c \
../src/ST7735_program.c \
../src/STP_program.c \
../src/SYSTICK_program.c \
../src/TIM_program.c \
../src/ULTRASONIC_program.c \
../src/USART_program.c \
../src/main.c 

OBJS += \
./src/BTM_program.o \
./src/BUZZER_program.o \
./src/EXTI_program.o \
./src/GPIO_program.o \
./src/IR_REMOTE_program.o \
./src/LEDMATRIX_program.o \
./src/MOTOR_DRIVER_program.o \
./src/MRCC_program.o \
./src/NVIC_program.o \
./src/OS_program.o \
./src/SERVO_program.o \
./src/SPI_program.o \
./src/ST7735_program.o \
./src/STP_program.o \
./src/SYSTICK_program.o \
./src/TIM_program.o \
./src/ULTRASONIC_program.o \
./src/USART_program.o \
./src/main.o 

C_DEPS += \
./src/BTM_program.d \
./src/BUZZER_program.d \
./src/EXTI_program.d \
./src/GPIO_program.d \
./src/IR_REMOTE_program.d \
./src/LEDMATRIX_program.d \
./src/MOTOR_DRIVER_program.d \
./src/MRCC_program.d \
./src/NVIC_program.d \
./src/OS_program.d \
./src/SERVO_program.d \
./src/SPI_program.d \
./src/ST7735_program.d \
./src/STP_program.d \
./src/SYSTICK_program.d \
./src/TIM_program.d \
./src/ULTRASONIC_program.d \
./src/USART_program.d \
./src/main.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM GNU C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -mfloat-abi=soft -Og -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -ffreestanding -fno-move-loop-invariants -Wall -Wextra  -g3 -DDEBUG -DUSE_FULL_ASSERT -DTRACE -DOS_USE_TRACE_SEMIHOSTING_DEBUG -DSTM32F401xC -DUSE_HAL_DRIVER -DHSE_VALUE=16000000 -I"../include" -I"../system/include" -I"../system/include/cmsis" -I"../system/include/stm32f4-hal" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


