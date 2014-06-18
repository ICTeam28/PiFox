@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global setup_sound
.global update_sound

.include "ports.s"

@ ------------------------------------------------------------------------------
@ Macro that simplifies adding new sounds
@ ------------------------------------------------------------------------------
.macro sound name
  .long 0                    @ Play flag
  .long \name\()_start       @ Address of current chunk
  .long \name\()_start       @ Start address of sample
  .long \name\()_end         @ End address of sample
  .global snd_play_\name
  snd_play_\name:            @ Start playing
    push  {r0}
    mov   r0, #1
    str   r0, [pc, #-32]
    pop   {r0}
    mov   pc, lr
  .global snd_stop_\name
  snd_stop_\name:
    push  {r0}
    mov   r0, #0
    str   r0, [pc, #-52]
    pop   {r0}
    mov   pc, lr
.endm

.section .text
@ ------------------------------------------------------------------------------
@ Initialises the sound module, setting up GPIO 40 and 45 to use PWM and
@ programming DMA channel 1 with two control blocks chained together that
@ write data to the GPIO ports
@
@ Arguments:
@   none
@ Returns:
@   none
@ Clobbers:
@   r0 - r3
@ ------------------------------------------------------------------------------
setup_sound:
  @ Copy first chunk of background music into buffers
  ldr         r0, =corneria_start
  ldr         r1, =dma_buffer_0
  ldr         r2, =0x2000
  mov         r3, #0
1:
  ldrb        r3, [r0], #1
  str         r3, [r1], #4
  subs        r2, r2, #1
  bne         1b

  ldr         r1, =dma_buffer_1
  ldr         r2, =0x2000
1:
  ldrb        r3, [r0], #1
  str         r3, [r1], #4
  subs        r2, r2, #1
  bne         1b

  @ Set GPIO 40 & 45 to PWM
  ldr         r0, =GPIO_FSEL4
  ldr         r1, [r0]
  ldr         r2, =0x00038007
  bic         r1, r1, r2
  ldr         r2, =0x00020004
  orr         r1, r1, r2
  str         r1, [r0]

  @ Setup clock
  ldr         r0, =CM_PWMDIV
  ldr         r1, =0x5A002000
  str         r1, [r0]
  ldr         r0, =CM_PWMCTL
  ldr         r1, =0x5A000016
  str         r1, [r0]

  @ Setup PWM
  ldr         r1, =0x00002C48
  ldr         r0, =PWM_RNG1
  str         r1, [r0]
  ldr         r0, =PWM_RNG2
  str         r1, [r0]
  ldr         r0, =PWM_CTL
  ldr         r1, =0x00002161
  str         r1, [r0]

  @ Setup PWM to use DMA
  ldr         r0, =PWM_DMAC
  ldr         r1, =0x80000001
  str         r1, [r0]

  @ Enable DMA0
  ldr         r0, =DMA_ENABLE
  ldr         r1, =0x00000001
  str         r1, [r0]

  @ Set DMA0 control block
  ldr         r0, =DMA0_CONBLK
  adr         r1, DMA_CTRL_1
  str         r1, [r0]

  @ Start DMA0
  ldr         r0, =DMA0_CS
  ldr         r1, =0x00000001
  str         r1, [r0]

  mov         pc, lr

@ ------------------------------------------------------------------------------
@ Should be called when DMA triggers an interrupt, but unfortunately the
@ hardware seems incapable of triggering it. Fortunately, we can poll for the
@ interrupt flag in the DMA interrupt status register and call the function
@ ourselves
@
@ Arguments:
@   none
@ Clobbers:
@   none
@ Returns:
@   none
@ ------------------------------------------------------------------------------
update_sound:
  stmfd       sp!, {r0 - r10, lr}

  ldr         r0, =DMA_INT_STATUS
  ldr         r1, [r0]
  tst         r1, r1
  ldmeqfd     sp!, {r0 - r10, pc}

  ldr         r0, =DMA0_CS
  ldr         r1, =0x00000005
  str         r1, [r0]

  @ Swap buffers
  ldr         r1, =buffer_index
  ldr         r0, [r1]
  add         r0, r0, #1
  and         r0, r0, #1
  str         r0, [r1]

  @ Find target buffer
  tst         r0, r0
  ldrne       r0, =dma_buffer_0
  ldreq       r0, =dma_buffer_1

  @ Copy background sound
  ldr         r1, =corneria_start
  ldr         r2, =corneria_ptr
  ldr         r3, [r2]
  ldr         r4, =corneria_end
  sub         r4, r4, #0x2000
  add         r3, r3, #0x2000
  cmp         r3, r4
  movge       r3, r1
  str         r3, [r2]

  ldr         r4, =0x2000
  mov         r2, r0
1:
  ldrb        r5, [r3], #1
  lsl         r5, r5, #3
  str         r5, [r2], #4
  subs        r4, r4, #1
  bne         1b

  @ Play sounds
  ldr         r9, =sounds
  mov         r10, #9
1:
  ldr         r5, [r9]
  tst         r5, r5
  beq         3f

  ldr         r5, [r9, #4]
  ldr         r3, =0x2000
  mov         r7, r0
2:
  ldrb        r6, [r5], #1
  sub         r6, r6, #0x7F
  ldr         r8, [r7]
  add         r8, r8, r6, lsl #3
  str         r8, [r7], #4

  subs        r3, r3, #1
  bne         2b

  ldr         r3, [r9, #8]
  ldr         r4, [r9, #12]
  cmp         r5, r4
  movge       r5, r3
  str         r5, [r9, #4]
  movge       r5, #0
  strge       r5, [r9]
3:
  add         r9, #56
  subs        r10, r10, #1
  bne         1b

  ldmfd       sp!, {r0 - r10, pc}


.ltorg
.section .text
@ ------------------------------------------------------------------------------
@ DMA control structures - chained after each other
@ ------------------------------------------------------------------------------
.align 5
DMA_CTRL_0:
  .long 0x00050141    @ Attributes
  .long dma_buffer_0  @ Source address
  .long 0x7E20C018    @ Destination Address
  .long 0x8000        @ Transfer length
  .long 0
  .long DMA_CTRL_1

.align 5
DMA_CTRL_1:
  .long 0x00050141    @ Attributes
  .long dma_buffer_1  @ Source address
  .long 0x7E20C018    @ Destination Address
  .long 0x8000        @ Transfer length
  .long 0
  .long DMA_CTRL_0


.align 4
@ ------------------------------------------------------------------------------
@ DMA buffers
@ ------------------------------------------------------------------------------
dma_buffer_0:
  .space 0x8000, 0
dma_buffer_1:
  .space 0x8000, 0


.align 2
@ ------------------------------------------------------------------------------
@ Sound effect states
@ ------------------------------------------------------------------------------
buffer_index:
  .long 1

sounds:
  sound bullet
  sound roll
  sound rock
  sound crash
  sound fail
  sound boost
  sound rocket
  sound cantlet
  sound pickup

.section .data
@ ------------------------------------------------------------------------------
@ Background music
@ ------------------------------------------------------------------------------
corneria_start: .incbin "assets/corneria.bin"
corneria_end:
corneria_ptr:   .long corneria_start

@ ------------------------------------------------------------------------------
@ Short sounds effects
@ ------------------------------------------------------------------------------
bullet_start:   .incbin "assets/laser.bin"
bullet_end:
roll_start:     .incbin "assets/roll.bin"
roll_end:
rock_start:     .incbin "assets/rocknroll.bin"
rock_end:
crash_start:    .incbin "assets/crash.bin"
crash_end:
fail_start:     .incbin "assets/fail.bin"
fail_end:
boost_start: 	  .incbin "assets/boost.bin"
boost_end:
rocket_start:   .incbin "assets/rocketsound.bin"
rocket_end:
cantlet_start:  .incbin "assets/cantletyou.bin"
cantlet_end:
pickup_start:   .incbin "assets/pickup.bin"
pickup_end:
