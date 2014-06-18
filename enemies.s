@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global setup_enemies
.global draw_enemies
.global reset_enemies
.global reset_flares
.global enemy_count
.global enemies
.global ENEMY_COUNT

.section .data
@ ------------------------------------------------------------------------------
@ List of enemies
@ ------------------------------------------------------------------------------
.equ ENEMY_COUNT,    5
.equ FLARE_COUNT,    30

enemy_count:    .long 0
enemy_counter:  .long 0
enemy_timer:    .long 0
enemies:
  .rept ENEMY_COUNT
    .float 0.0, 0.0, 0.0      @ x, y, z
    .float 0.0                @ s3 - target z
    .float 0.0                @ s4 - rot
    .float 0.0                @ s5 - move dir
    .long  0                  @ s6 - lives
    .long  0                  @ s7 - bullet timer
  .endr

flares:
  .rept FLARE_COUNT
    .float 0.0, 0.0, -20.0    @ x, y, z
    .float 0.0, 0.0,   0.0    @ dx, dy, dz
    .long 0                   @ s6 - alive
  .endr

.section .text
@ ------------------------------------------------------------------------------
@ Resets counters
@ ------------------------------------------------------------------------------
setup_enemies:
  ldr         r0, =enemy_count
  mov         r1, #0
  str         r1, [r0]

  ldr         r0, =enemy_counter
  mov         r1, #0
  str         r1, [r0]

  ldr         r0, =enemy_timer
  mov         r1, #1000
  str         r1, [r0]

  mov         pc, lr

@ ------------------------------------------------------------------------------
@ Renders all enemies
@ ------------------------------------------------------------------------------
draw_enemies:
  stmfd       sp!, {lr}

  ldr         r0, =enemy_count
  ldr         r0, [r0]
  tst         r0, r0
  bne         2f

  @ Test if enemies can be spawned
  ldr         r0, =enemy_timer
  ldr         r1, [r0]
  subs        r1, r1, #1
  moveq       r1, #1000
  str         r1, [r0]
  ldmnefd     sp!, {pc}

  @ Pop-up the monkey
  ldr         r0, =monkey_timer
  mov         r1, #120
  str         r1, [r0]

  @ Play cant let you do that
  bl          snd_play_cantlet

  @ Increment number of enemies, clamp to 5
  ldr         r0, =enemy_counter
  ldr         r11, [r0]
  add         r11, r11, #1
  cmp         r11, #5
  movgt       r11, #5
  str         r11, [r0]
  ldr         r0, =enemy_count
  str         r11, [r0]

  @ Initialise them
  ldr         r12, =enemies
  mov         r10, #0
1:
  bl          spawn_enemy
  vstm.f32    r12!, {s0 - s7}
  subs        r11, r11, #1
  bne         1b

2:
  ldr         r12, =enemies
  ldr         r11, =enemy_count
  ldr         r11, [r11]
  mov         r10, #0
3:
  @ Update & draw enemies
  vldm.f32    r12, {s0 - s7}
  vmov.f32    r0, s6
  tst         r0, r0
  addeq       r12, r12, #32
  beq         4f
  bl          update_enemy
  vstm.f32    r12!, {s0 - s7}
  vmov.f32    r0, s6
  tst         r0, r0
  blne        draw_enemy
4:
  subs        r11, r11, #1
  bne         3b

  tst         r10, r10
  ldr         r11, =enemy_count
  streq       r10, [r11]

  @ Reset model matrix
  ldr         r0, =mtx_id
  vldm.f32    r0, {s0 - s15}
  ldr         r0, =mtx_model
  vstm.f32    r0, {s0 - s15}

  @ Draw flares shot by enemies
  ldr         r11, =FLARE_COUNT
  ldr         r12, =flares
1:
  vldm.f32    r12, {s0 - s6}
  vmov.f32    r0, s6
  tst         r0, r0
  addeq       r12, r12, #28
  beq         2f
  bl          update_flare
  vstm.f32    r12!, {s0 - s6}
  bl          draw_flare
2:
  subs        r11, r11, #1
  bne         1b

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Updates an enemy
@ Arguments:
@
@ Returns:
@
@ Clobbers:
@
@ ------------------------------------------------------------------------------
update_enemy:
  stmfd       sp!, {lr}

  @ Move down z axis up to target z
  ldr         r0, =player_speed
  vldr.f32    s8, [r0]
  vadd.f32    s2, s2, s8
  ldr         r0, =0x3f800000
  vmov.f32    s9, r0
  vadd.f32    s2, s2, s9
  vcmp.f32    s2, s3
  fmstat
  vmovgt.f32  s2, s3

  @ Lateral movement
  vadd.f32    s0, s0, s5
  ldr         r0, =0xc1080000
  vmov.f32    s8, r0
  vcmp.f32    s0, s8
  fmstat
  vmovlt.f32  s0, s8
  vneglt.f32  s5, s5
  vneg.f32    s8, s8
  vcmp.f32    s0, s8
  fmstat
  vmovgt.f32  s0, s8
  vneggt.f32  s5, s5

  @ Rotation
  ldr         r0, =0x3c23d70a
  vmov.f32    s8, r0
  vadd.f32    s4, s4, s8

  @ Decrement bullet timeout
  vmov.f32    r0, s7
  subs        r0, r0, #1
  moveq       r0, #40
  vmov.f32    s7, r0
  bne         2f

  @ Fire a flare
  vcmp.f32    s2, s3
  fmstat
  blge        fire_flare

2:
  @ Test for collision with bullets
  ldr         r0, =0x40000000
  vmov.f32    s31, r0
  bl          collide_bullets
  tst         r0, r0
  vmoveq.f32  r0, s6
  subeq       r0, r0, #1
  vmoveq.f32  s6, r0

  @ Increment score
  ldreq       r0, =player_score     @ Add to score
  ldreq       r1, [r0]
  addeq       r1, r1, #50
  streq       r1, [r0]

  @ Increment live enemy count
  add         r10, r10, #1

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Renders an enemy
@ Arguments:
@   none
@ Returns:
@   none
@ Clobbers:
@   s0 - s31
@ ------------------------------------------------------------------------------
draw_enemy:
  stmfd       sp!, {lr}

  ldr         r0, =mtx_id
  vldm.f32    r0, {s16 - s31}
  ldr         r0, =mtx_model
  vstm.f32    r0, {s16 - s31}
  ldr         r0, =mtx_temp
  vstm.f32    r0, {s16 - s31}

  @ Damage
  vmov.f32    r5, s6
  subs        r5, r5, #1
  mov         r6, #4
  mov         r7, #3
  mla         r5, r7, r5, r6

  @ Translate & rotate
  vneg.f32    s1, s1
  ldr         r0, =mtx_model
  bl          mat4_translate
  vmov.f32    s0, s4
  ldr         r0, =mtx_temp
  bl          mat4_rot_z
  ldr         r0, =mtx_model
  ldr         r1, =mtx_temp
  ldr         r2, =mtx_model
  bl          mat4_mul_mat4

  @ Compute MVP matrix
  ldr         r0, =mtx_vp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_mvp
  bl          mat4_mul_mat4

  @ Draw the enemy
  ldr         r0, =enemy_vtx
  ldr         r1, =enemy_idx
  mov         r2, r5
  ldr         r3, =mtx_mvp
  ldr         r4, =light_dir
  bl          gfx_draw_trgs

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Creates a randomized enemy
@ Arguments:
@   r10 - index of enemy
@ Returns:
@   s0 - s5: enemy data
@ Clobbers:
@   Increments r10
@ ------------------------------------------------------------------------------
spawn_enemy:
  stmfd       sp!, {lr}

  @ Randomize x in range [-8.5, 8.5]
  bl          random
  and         r1, r0, #0xFF
  sub         r1, r1, #0x7F
  vmov.f32    s8, r1
  fsitos      s8, s8
  ldr         r1, =0x41400000
  vmov.f32    s9, r1
  vdiv.f32    s0, s8, s9

  @ Randomize y in range [-2.8, 5.2]
  bl          random
  and         r1, r0, #0xFF
  sub         r1, r1, #0x7F
  vmov.f32    s8, r1
  fsitos      s8, s8
  ldr         r1, =0x42700000
  vmov.f32    s9, r1
  vdiv.f32    s1, s8, s9

  @ Set z to -300.0
  ldr         r0, =0xc3960000
  vmov.f32    s2, r0

  vmov.f32    s8, r10
  fsitos      s8, s8
  ldr         r0, =0x40a00000
  vmov.f32    s9, r0
  vmul.f32    s8, s8, s9
  ldr         r0, =0xc2480000
  vmov.f32    s9, r0
  vsub.f32    s3, s9, s8

  @ Rotation
  ldr         r0, =0
  vmov.f32    s4, r0

  @ Random lateral movement
  ldr         r0, =0x3e4ccccd
  vmov.f32    s5, r0
  bl          random
  tst         r0, #1
  vnegne.f32  s5, s5
  and         r0, #1
  add         r0, #1
  vmov.f32    s8, r0
  fsitos      s8, s8
  vmul.f32    s5, s5, s8

  @ Lives
  mov         r0, #5
  vmov.f32    s6, r0

  @ Bullet timer
  mov         r1, #15
  add         r10, r10, #1
  mul         r0, r1, r10
  vmov.f32    s7, r0

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Updates a flare
@ Arguments:
@   none
@ Returns:
@   none
@ Clobers:
@   none
@ ------------------------------------------------------------------------------
update_flare:
  stmfd       sp!, {lr}

  vadd.f32    s0, s0, s3
  vadd.f32    s1, s1, s4
  vadd.f32    s2, s2, s5

  @ Check whether bullet is still active
  ldr         r0, =0xc1200000
  vmov.f32    s31, r0
  vcmp.f32    s2, s31
  fmstat
  ldmltfd     sp!, {pc}

  @ Despawn bullet and damage player
  mov         r0, #0
  vmov.f32    s6, r0

  ldr         r0, =player_pos
  vldm.f32    r0, {s30 - s31}
  vsub.f32    s7, s0, s30
  vabs.f32    s7, s7
  vsub.f32    s8, s1, s31
  vabs.f32    s8, s8

  ldr         r0, =0x3fe00000
  vmov.f32    s9, r0

  vcmp.f32    s7, s9
  fmstat
  ldmgtfd     sp!, {pc}
  vcmp.f32    s8, s9
  fmstat
  ldmgtfd     sp!, {pc}

  ldr         r0, =player_rolling
  ldr         r0, [r0]
  tst         r0, r0
  ldmnefd     sp!, {pc}

  mov         r0, #20
  bl          player_damage
1:
  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Draws a flare
@ Arguments:
@   s0 - s2: position
@ Returns:
@   none
@ Clobers:
@   none
@ ------------------------------------------------------------------------------
draw_flare:
  stmfd       sp!, {lr}

  ldr         r0, =mtx_model
  vneg.f32    s1, s1
  bl          mat4_translate

  ldr         r0, =mtx_vp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_mvp
  bl          mat4_mul_mat4

  @ Draw a sprite
  ldr         r0, =flare
  ldr         r1, =mtx_mvp
  ldr         r2, =mtx_view
  ldr         r3, =0x3e800000
  vmov.f32    s0, r3
  vmov.f32    s1, r3
  bl          gfx_draw_sprite

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Fires a flare
@ Arguments:
@   none
@ Returns:
@   none
@ Clobers:
@   none
@ ------------------------------------------------------------------------------
fire_flare:
  stmfd       sp!, {r11 - r12, lr}

  @ Load player position
  ldr         r11, =player_pos
  vldm.f32    r11, {s22 - s24}

  @ Draw flares shot by enemies
  ldr         r11, =FLARE_COUNT
  ldr         r12, =flares
1:
  vldm.f32    r12, {s25 - s31}
  vmov.f32    r0, s31
  tst         r0, r0
  addne       r12, r12, #28
  beq         2f
  subs        r11, r11, #1
  bne         1b

2:
  @ Position
  vmov.f32    s25, s0
  vmov.f32    s26, s1
  vmov.f32    s27, s2
  vabs.f32    s21, s27

  @ Direction
  vsub.f32    s28, s22, s25
  vsub.f32    s29, s23, s26
  vsub.f32    s30, s24, s27

  vdiv.f32    s28, s28, s21
  vdiv.f32    s29, s29, s21
  vdiv.f32    s30, s30, s21

  @ Live flag
  mov         r0, #1
  vmov.f32    s31, r0

  vstm.f32    r12!, {s25 - s31}

  ldmfd       sp!, {r11 - r12, pc}

@-------------------------------------------------------------------------------
@ Resets enemies
@-------------------------------------------------------------------------------
reset_enemies:
  stmfd       sp!, {r0 - r2, lr}
  vstmdb.f32  sp!, {s0 - s7}

  ldr         r2, =ENEMY_COUNT
  ldr         r1, =enemies
  mov         r0, #0

1:
  vldm.f32    r1, {s0 - s7}

  vmov.f32    s0, r0
  vmov.f32    s1, r0
  vmov.f32    s2, r0
  vmov.f32    s3, r0
  vmov.f32    s4, r0
  vmov.f32    s5, r0
  vmov.f32    s6, r0
  vmov.f32    s7, r0

  vstm.f32    r1!, {s0 - s7}

  subs        r2, #1
  bne         1b

  vldmia.f32  sp!, {s0 - s7}
  ldmfd       sp!, {r0 - r2, pc}

@-------------------------------------------------------------------------------
@ Resets flares
@-------------------------------------------------------------------------------
reset_flares:
  stmfd       sp!, {r0 - r3, lr}
  vstmdb.f32  sp!, {s0 - s6}

  ldr         r3, =FLARE_COUNT
  ldr         r2, =flares
  ldr         r1, =0xC1A00000      @ r1 = -20
  mov         r0, #0

1:
  vldm.f32    r2, {s0 - s6}

  vmov.f32    s0, r0
  vmov.f32    s1, r0
  vmov.f32    s2, r1
  vmov.f32    s3, r0
  vmov.f32    s4, r0
  vmov.f32    s5, r0
  vmov.f32    s6, r0

  vstm.f32    r2!, {s0 - s6}

  subs        r3, #1
  bne         1b

  vldmia.f32  sp!, {s0 - s6}
  ldmfd       sp!, {r0 - r3, pc}
