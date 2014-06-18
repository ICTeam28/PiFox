@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global draw_bullets
.global collide_bullets
.global reset_bullets

.include "ports.s"

.section .data
@ ------------------------------------------------------------------------------
@ List of bullets
@ ------------------------------------------------------------------------------
.equ          BULLET_COUNT, 20
bullet_last:  .long 0
bullet_list:
  .rept BULLET_COUNT
    .float 0.0, 0.0, 0.0, 1.0
    .long  0
  .endr

.section .text
@ ------------------------------------------------------------------------------
@ Renders all bullets
@ ------------------------------------------------------------------------------
draw_bullets:
  stmfd       sp!, {lr}

  @ Reset model matrix
  ldr         r0, =mtx_id
  vldm.f32    r0, {s0 - s15}
  ldr         r0, =mtx_model
  vstm.f32    r0, {s0 - s15}

  @ Read system timer
  ldr         r7, =STIMER_CLO
  ldr         r7, [r7]

  @ Loop through all bullets
  ldr         r12, =BULLET_COUNT
  ldr         r11, =bullet_list
  ldr         r10, =bullet_last
  ldr         r6, [r10]
1:
  vldmia.f32  r11!, {s3 - s6}
  ldmia       r11!, {r9}

  ldr         r0, =0x40400000
  vmov.f32    s2, r0
  vsub.f32    s5, s5, s2

  tst         r9, r9
  bne         2f

  @ Check if sprite can be spawned
  sub         r8, r7, r6
  cmp         r8, #0x50000
  blt         2f

  ldr         r5, =button_pressed
  ldr         r5, [r5]
  tst         r5, #0x01
  beq         2f

  @ Play shot sound
  bl          snd_play_bullet

  @ Spawn a new sprite
  add         r9, r7, #0x100000
  mov         r6, r7
  str         r7, [r10]

  ldr         r0, =player_pos
  vldm.f32    r0, {s3 - s6}
  ldr         r1, =0xc0000000
  vmov.f32    s7, r1
  vsub.f32    s4, s4, s7
  ldr         r1, =0xc1200000
  vmov.f32    s5, r1
  b           3f
2:
  cmp         r9, r7
  movlt       r9, #0
3:
  stmdb       r11!, {r9}
  vstmdb      r11!, {s3 - s6}

  @ Check if bullet is active
  tst         r9, r9
  blne        draw_bullet

2:
  add         r11, r11, #20
  subs        r12, r12, #1
  bne         1b

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Renders a single bullet
@ ------------------------------------------------------------------------------
draw_bullet:
  stmfd       sp!, {lr}

  ldr         r0, =mtx_model
  vmov.f32    s0, s3
  vneg.f32    s1, s4
  vmov.f32    s2, s5
  bl          mat4_translate

  ldr         r0, =mtx_vp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_mvp
  bl          mat4_mul_mat4

  @ Draw a sprite
  ldr         r0, =bullet
  ldr         r1, =mtx_mvp
  ldr         r2, =mtx_view
  ldr         r3, =0x3e800000
  vmov.f32    s0, r3
  vmov.f32    s1, r3
  bl          gfx_draw_sprite

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Checks whether the bullet collided with something.
@ In case of a collision, the bullet is destroyed
@ Arguments:
@   s0 - x
@   s1 - y
@   s2 - z
@   s31 - radius
@ Returns:
@   r0 - 0 if collision happened
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
collide_bullets:
  stmfd       sp!, {r1 - r12, lr}
  mov         r0, #1

  ldr         r12, =BULLET_COUNT
  ldr         r11, =bullet_list
1:
  vldmia.f32  r11!, {s27 - s30}
  ldmia       r11!, {r9}

  tst         r9, r9
  beq         2f

  vsub.f32    s26, s0, s27
  vabs.f32    s26, s26
  vcmp.f32    s26, s31
  fmstat
  bgt         2f            @ x

  vsub.f32    s26, s1, s28
  vabs.f32    s26, s26
  vcmp.f32    s26, s31
  fmstat
  bgt         2f            @ y

  vsub.f32    s26, s2, s29
  vabs.f32    s26, s26
  vcmp.f32    s26, s31
  fmstat
  bgt         2f            @ z

  mov         r0, #0
  str         r0, [r11, #-4]
  b           3f
2:
  subs        r12, r12, #1
  bne         1b
3:

  ldmfd       sp!, {r1 - r12, pc}

@-------------------------------------------------------------------------------
@ Resets bullets
@-------------------------------------------------------------------------------
reset_bullets:
  stmfd       sp!, {r0 - r3, lr}
  vstmdb.f32  sp!, {s0 - s4}

  ldr         r3, =bullet_last
  mov         r0, #0
  str         r0, [r3]

  ldr         r3, =BULLET_COUNT
  ldr         r2, =bullet_list
  ldr         r1, =0x3F800000      @ 1.0

1:
  vldm.f32    r2, {s0 -s4}

  vmov.f32    s0, r0
  vmov.f32    s1, r0
  vmov.f32    s2, r0
  vmov.f32    s3, r1
  vmov.f32    s4, r0

  vstm.f32    r2!, {s0 - s4}

  subs        r3, #1
  bne         1b

  vldm.f32    sp!, {s0 - s4}
  ldmfd       sp!, {r0 - r3, pc}
