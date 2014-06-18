@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global setup_input
.global update_input
.global button_pressed
.global button_clicked
.global button_dclicked
.include "ports.s"

@ ------------------------------------------------------------------------------
@ Macros used to wait for a while
@ ------------------------------------------------------------------------------
.macro wait reg, x
  mov     \reg, \x
9:
  subs    \reg, \reg, #1
  bne     9b
.endm

@ ------------------------------------------------------------------------------
@ Global variable storing the state of buttons
@ ------------------------------------------------------------------------------
.section .data
button_pressed:  .long 0  @ button is held down
button_clicked:  .long 0  @ button pressed during frame
button_hclicked: .long 0  @ button pressed during last 30 frames
button_dclicked: .long 0  @ button pressed twice
button_lclicked: .long 0  @ Last time button was clicked

.section .text
@ ------------------------------------------------------------------------------
@ Initialises the input module
@ ------------------------------------------------------------------------------
setup_input:
  stmfd     sp!, {r0 - r2}

  @ Setup GPIO ports 10 and 11 as outputs
  ldr       r0, =GPIO_FSEL1
  ldr       r1, [r0]
  ldr       r2, =0xFFFFFFC0
  and       r1, r1, r2
  mov       r2, #0x00000009
  orr       r1, r1, r2
  str       r1, [r0]

  ldmfd     sp!, {r0 - r2}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Updates the state machine on receipt of an interrupt
@   GPIO 4 - data in
@   GPIO 10 - pulse
@   GPIO 11 - latch
@ ------------------------------------------------------------------------------
update_input:
  stmfd     sp!, {r0 - r9, lr}

  ldr       r0, =GPIO_SET0
  ldr       r1, =GPIO_CLR0
  ldr       r2, =GPIO_LEV0

  ldr       r3, =button_pressed
  ldr       r3, [r3]
  ldr       r4, =button_hclicked
  ldr       r4, [r4]

  ldr       r5, =button_lclicked
  ldr       r6, [r5]
  tst       r4, r4
  moveq     r6, #0
  addne     r6, r6, #1
  cmp       r6, #15
  movge     r6, #0
  movge     r7, r4
  movlt     r7, #0
  movge     r4, #0
  str       r6, [r5]

  ldr       r5, =button_clicked
  str       r7, [r5]

  ldr       r5, =button_dclicked
  ldr       r5, [r5]
  mov       r5, #0

  @ Latch
  mov       r6, #0x800
  str       r6, [r0]
  wait      r12, #128
  str       r6, [r1]
  wait      r12, #128

  mov       r7, #0
  mov       r8, #8
  mov       r9, #1
1:
  @ Read button state
  ldr       r6, [r2]
  tst       r6, #0x10
  bne       3f
  orr       r7, r7, r9
  tst       r3, r9
  bne       3f
  tst       r4, r9
  orreq     r4, r4, r9        @ Click: up -> down
  biceq     r5, r5, r9
  bicne     r4, r4, r9
  orrne     r5, r5, r9        @ Double click: up -> down -> up -> down
3:

  @ Pulse
  mov       r6, #0x400
  str       r6, [r0]
  wait      r12, #128
  str       r6, [r1]
  wait      r12, #128

  lsl       r9, r9, #1
  subs      r8, r8, #1
  bgt       1b

  teq       r7, #0xFF
  moveq     r7, #0

  ldr       r0, =button_pressed
  str       r7, [r0]
  ldr       r0, =button_hclicked
  str       r4, [r0]
  ldr       r0, =button_dclicked
  str       r5, [r0]

  ldmfd     sp!, {r0 - r9, pc}
