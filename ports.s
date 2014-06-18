@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.

@ ------------------------------------------------------------------------------
@ System timer
@ ------------------------------------------------------------------------------
.equ STIMER_CS,        0x20003000
.equ STIMER_CLO,       0x20003004
.equ STIMER_CHI,       0x20003008
.equ STIMER_C0,        0x2000300C
.equ STIMER_C1,        0x20003010
.equ STIMER_C2,        0x20003014
.equ STIMER_C3,        0x20003018

@ ------------------------------------------------------------------------------
@ Interrupt register
@ ------------------------------------------------------------------------------
.equ IRQ_PENDING,      0x2000B200
.equ IRQ_GPU_PENDING1, 0x2000B204
.equ IRQ_GPU_PENDING2, 0x2000B208
.equ IRQ_FIQ,          0x2000B20C
.equ IRQ_EN1,          0x2000B210
.equ IRQ_EN2,          0x2000B214
.equ IRQ_ENB,          0x2000B218
.equ IRQ_DS1,          0x2000B21C
.equ IRQ_DS2,          0x2000B220
.equ IRQ_DSB,          0x2000B224

@ ------------------------------------------------------------------------------
@ ARM timer
@ ------------------------------------------------------------------------------
.equ TIMER_LOD,        0x2000B400
.equ TIMER_VAL,        0x2000B404
.equ TIMER_CTL,        0x2000B408
.equ TIMER_CLI,        0x2000B40C
.equ TIMER_RIS,        0x2000B410
.equ TIMER_MIS,        0x2000B414
.equ TIMER_RLD,        0x2000B418
.equ TIMER_DIV,        0x2000B41C
.equ TIMER_CNT,        0x2000B420

@ ------------------------------------------------------------------------------
@ Mailbox Ports
@ ------------------------------------------------------------------------------
.equ MBOX_BASE,        0x2000B880
.equ MBOX_READ,        0x2000B880
.equ MBOX_POLL,        0x2000B890
.equ MBOX_SENDER,      0x2000B894
.equ MBOX_STATUS,      0x2000B898
.equ MBOX_CONFIG,      0x2000B89C
.equ MBOX_WRITE,       0x2000B8A0

@ ------------------------------------------------------------------------------
@ GPIO Ports
@ ------------------------------------------------------------------------------
.equ GPIO_FSEL0,       0x20200000
.equ GPIO_FSEL1,       0x20200004
.equ GPIO_FSEL2,       0x20200008
.equ GPIO_FSEL3,       0x2020000C
.equ GPIO_FSEL4,       0x20200010
.equ GPIO_FSEL5,       0x20200014
.equ GPIO_SET0,        0x2020001C
.equ GPIO_SET1,        0x20200020
.equ GPIO_CLR0,        0x20200028
.equ GPIO_CLR1,        0x2020002C
.equ GPIO_LEV0,        0x20200034
.equ GPIO_LEV1,        0x20200038
.equ GPIO_EDS0,        0x20200040
.equ GPIO_EDS1,        0x20200044
.equ GPIO_REN0,        0x2020004C
.equ GPIO_REN1,        0x20200050
.equ GPIO_FEN0,        0x20200058
.equ GPIO_FEN1,        0x2020005C
.equ GPIO_HEN0,        0x20200064
.equ GPIO_HEN1,        0x20200068
.equ GPIO_LEN0,        0x20200070
.equ GPIO_LEN1,        0x20200074
.equ GPIO_AREN0,       0x2020007C
.equ GPIO_AREN1,       0x20200080
.equ GPIO_AFEN0,       0x20200088
.equ GPIO_AFEN1,       0x2020008C
.equ GPIO_PUD,         0x20200094
.equ GPIO_UDCLK0,      0x20200098
.equ GPIO_UDCLK1,      0x2020009C

@ ------------------------------------------------------------------------------
@ PL011 UART Ports
@ ------------------------------------------------------------------------------
.equ UART_DR,          0x20201000
.equ UART_RSECR,       0x20201004
.equ UART_FR,          0x20201018
.equ UART_ILPR,        0x20201020
.equ UART_IBRD,        0x20201024
.equ UART_FBRC,        0x20201028
.equ UART_LCRH,        0x2020102C
.equ UART_CR,          0x20201030
.equ UART_IFLS,        0x20201034
.equ UART_IMSC,        0x20201038
.equ UART_RIS,         0x2020103C
.equ UART_MIS,         0x20201040
.equ UART_ICR,         0x20201044
.equ UART_DMACR,       0x20201048
.equ UART_ITCR,        0x20201080
.equ UART_ITIP,        0x20201084
.equ UART_ITOP,        0x20201088
.equ UART_TDR,         0x2020108C

@ ------------------------------------------------------------------------------
@ Clock manager
@ ------------------------------------------------------------------------------
.equ CM_PWMCTL,        0x201010A0
.equ CM_PWMDIV,        0x201010A4

@ ------------------------------------------------------------------------------
@ Direct Memory Access
@ ------------------------------------------------------------------------------
.equ DMA0_CS,          0x20007000
.equ DMA0_CONBLK,      0x20007004
.equ DMA_INT_STATUS,   0x20007FE0
.equ DMA_ENABLE,       0x20007FF0

@ ------------------------------------------------------------------------------
@ Pulse Width modulator
@ ------------------------------------------------------------------------------
.equ PWM_CTL,          0x2020C000
.equ PWM_STA,          0x2020C004
.equ PWM_DMAC,         0x2020C008
.equ PWM_RNG1,         0x2020C010
.equ PWM_DAT1,         0x2020C014
.equ PWM_FIF1,         0x2020C018
.equ PWM_RNG2,         0x2020C020
.equ PWM_DAT2,         0x2020C024
