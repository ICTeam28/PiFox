@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global player_pos
.global player_health
.global player_rolling
.global player_speed
.global player_shake
.global player_score
.global player_high_score
.global player_wrenches
.global player_rockets
.global draw_player
.global player_damage
.global update_player
.global setup_player
.global reset_player_mov
.global monkey_timer
.global rock_timer

.section .data
@ ------------------------------------------------------------------------------
@ Player resources
@ ------------------------------------------------------------------------------
player_charge:      .long 0
player_health:      .long 200
player_wrenches:    .long 3
player_rockets:     .long 3
tristan_timer:      .long 0
monkey_timer:       .long 0
rock_timer:         .long 0

@ ------------------------------------------------------------------------------
@ Player movement
@ ------------------------------------------------------------------------------
player_tilt_z:      .float 0.0
player_tilt_x:      .float 0.0
player_rolling:     .long 0
player_shake:       .long 0
player_score:       .long 0
player_high_score:  .long 0
player_roll_dir:    .float 0.15
player_pos:         .float 0.0, 0.0, 0.0
player_speed:       .float 0.0
player_speed_mod:   .long 0

.section .text
@ ------------------------------------------------------------------------------
@ Initialises the player
@ ------------------------------------------------------------------------------
setup_player:
  stmfd       sp!, {r0 - r1, lr}

  ldr         r0, =player_charge
  ldr         r1, =0
  str         r1, [r0]

  ldr         r0, =player_health
  ldr         r1, =200
  str         r1, [r0]

  ldr         r0, =player_wrenches
  ldr         r1, =3
  str         r1, [r0]

  ldr         r0, =player_rockets
  ldr         r1, =3
  str         r1, [r0]

  ldr         r0, =player_score
  mov         r1, #0
  str         r1, [r0]

  ldr         r0, =player_speed_mod
  mov         r1, #0
  str         r1, [r0]

  ldr         r0, =tristan_timer
  mov         r1, #0
  str         r1, [r0]

  ldr         r0, =monkey_timer
  mov         r1, #0
  str         r1, [r0]

  ldr         r0, =rock_timer
  mov         r1, #130
  str         r1, [r0]

  ldr         r0, =player_pos
  mov         r1, #0
  vmov.f32    s0, r1
  vmov.f32    s1, r1
  vmov.f32    s2, r1
  vstm.f32    r0, {s0 - s2}

  ldmfd       sp!, {r0 - r1, pc}

@ ------------------------------------------------------------------------------
@ Renders the player's plane
@ ------------------------------------------------------------------------------
draw_player:
  stmfd       sp!, {lr}

  @ Reset model matrix
  ldr         r0, =mtx_id
  vldm.f32    r0, {s0 - s15}
  ldr         r0, =mtx_model
  vstm.f32    r0, {s0 - s15}
  mov         r1, #0
  vmov.f32    s0, r1
  ldr         r1, =0xc0000000
  vmov.f32    s1, r1
  ldr         r1, =0xc0e00000
  vmov.f32    s2, r1
  bl          mat4_translate

  @ Tilt around Z
  ldr         r0, =mtx_id
  vldm.f32    r0, {s0 - s15}
  ldr         r0, =mtx_temp
  vstm.f32    r0, {s0 - s15}
  ldr         r0, =player_tilt_z
  vldr.f32    s0, [r0]
  ldr         r0, =mtx_temp
  bl          mat4_rot_z
  ldr         r0, =mtx_model
  ldr         r1, =mtx_temp
  ldr         r2, =mtx_model
  bl          mat4_mul_mat4

  @ Tilt around X
  ldr         r0, =mtx_id
  vldm.f32    r0, {s0 - s15}
  ldr         r0, =mtx_temp
  vstm.f32    r0, {s0 - s15}
  ldr         r0, =player_tilt_x
  vldr.f32    s0, [r0]
  ldr         r0, =mtx_temp
  bl          mat4_rot_x
  ldr         r0, =mtx_model
  ldr         r1, =mtx_temp
  ldr         r2, =mtx_model
  bl          mat4_mul_mat4

  @ Compute proj * model
  ldr         r0, =mtx_proj
  ldr         r1, =mtx_model
  ldr         r2, =mtx_mp
  bl          mat4_mul_mat4

  @ Draw the plane
  ldr         r0, =ship_vtx
  ldr         r1, =ship_idx
  ldr         r2, =22
  ldr         r3, =mtx_mp
  ldr         r4, =light_dir
  bl          gfx_draw_trgs

  @ Draw wrenches
  ldr         r3, =player_wrenches
  ldr         r3, [r3]
  ldr         r1, =582
  ldr         r2, =410
  ldr         r0, =wrench

  tst         r3, r3
  beq         2f
1:
  bl          gfx_draw_image
  sub         r1, r1, #20
  subs        r3, r3, #1
  bne         1b
2:

  @ Draw rockets
  ldr         r3, =player_rockets
  ldr         r3, [r3]
  mov         r1, #34
  ldr         r2, =410
  ldr         r0, =rocket

  tst         r3, r3
  beq         2f
1:
  bl          gfx_draw_image
  add         r1, r1, #20
  subs        r3, r3, #1
  bne         1b
2:

  @ Draw health bar
  ldr         r0, =522
  ldr         r1, =450
  ldr         r5, =player_health
  ldr         r6, =0xFF0000cc
  bl          draw_bar

  @ Draw charge bar
  mov         r0, #10
  ldr         r1, =450
  ldr         r5, =player_charge
  ldr         r6, =0xFFFF4400
  bl          draw_bar

  @ Test if monkey should pop-up
  ldr         r0, =monkey_timer
  ldr         r1, [r0]
  subs        r1, r1, #1
  str         r1, [r0]

  ble         2f

  @ Draw monkey
  ldr         r0, =124
  ldr         r1, =420
  ldr         r5, =monkey
  ldr         r6, =5f
  bl          draw_pop_up

  ldmfd       sp!, {pc}

2:

  @ Test if Tristan should pop-up
  ldr         r0, =tristan_timer
  ldr         r1, [r0]
  subs        r1, r1, #1
  str         r1, [r0]

  ble         3f

  @ Draw Tristan barrel roll
  ldr         r0, =124
  ldr         r1, =420
  ldr         r5, =tristan
  ldr         r6, =4f
  bl          draw_pop_up

  ldmfd       sp!, {pc}

3:

  @ Test if Tristan should pop-up
  ldr         r0, =rock_timer
  ldr         r1, [r0]
  subs        r1, r1, #1
  str         r1, [r0]

  ldmlefd     sp!, {pc}

  @ Draw Tristan rock-and-roll
  ldr         r0, =124
  ldr         r1, =420
  ldr         r5, =tristan
  ldr         r6, =6f
  bl          draw_pop_up

  ldmfd       sp!, {pc}

4:
  .ascii "\nDo a barrel roll!"
  .byte  0x0
  .align 2

5:
  .ascii "\nCan't let you do that PiFox!"
  .byte  0x0
  .align 2

6:
  .ascii "I see 'em up ahead.\nLet's Rock and Roll!"
  .byte  0x0
  .align 2

@ ------------------------------------------------------------------------------
@ Rotates the camera around origin
@ ------------------------------------------------------------------------------
update_player:
  stmfd       sp!, {lr}

  bl          do_barrel_roll
  bl          do_speed
  bl          do_movement
  bl          do_repair
  bl          do_rocket
  bl          do_charge
  bl          do_matrices

  bl          do_speed_inc

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Continues a barrell roll
@ ------------------------------------------------------------------------------
do_barrel_roll:
  stmfd       sp!, {lr}

  @ If we are already rolling, continue
  ldr         r0, =player_rolling
  ldr         r1, [r0]
  tst         r1, r1
  bne         1f

  @ Roll when left/right is double clicked
  ldr         r2, =button_dclicked
  ldr         r2, [r2]
  tst         r2, #0xC0
  ldmeqfd     sp!, {pc}

  @ Charge must be full
  ldr         r3, =player_charge
  ldr         r4, [r3]
  cmp         r4, #200
  ldmltfd     sp!, {pc}
  mov         r4, #0
  str         r4, [r3]

  @ Play sounds
  bl          snd_play_boost

  @ Start the roll
  ldr         r3, =player_roll_dir
  vldr.f32    s0, [r3]
  vabs.f32    s0, s0
  tst         r2, #0x80
  vnegne.f32  s0, s0
  vstr.f32    s0, [r3]
  mov         r1, #1
  str         r1, [r0]
  ldmfd       sp!, {pc}
1:
  @ Update rotation
  ldr         r2, =player_roll_dir
  vldr.f32    s0, [r2]
  ldr         r2, =player_tilt_z
  vldr.f32    s1, [r2]
  vadd.f32    s1, s1, s0

  vcmp.f32    s0, #0
  fmstat
  bgt         2f
  ldr         r3, =0xc0c90fdb
  vmov.f32    s2, r3
  vcmp.f32    s1, s2
  fmstat
  movlt       r1, #0
  vmovlt.f32  s1, r1
  b           3f
2:
  ldr         r3, =0x40c90fdb
  vmov.f32    s2, r3
  vcmp.f32    s1, s2
  fmstat
  movgt       r1, #0
  vmovgt.f32  s1, r1
3:
  str         r1, [r0]
  vstr.f32    s1, [r2]
  ldr         r0, =0x3f800000        @ 1.0

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Updates the movement speed of the player
@ ------------------------------------------------------------------------------
do_speed:
  ldr         r0, =player_speed_mod
  vldr.f32    s0, [r0]
  fsitos      s0, s0

  ldr         r0, =0x3a378034        @ 0.0007
  vmov.f32    s1, r0
  vmul.f32    s0, s0, s1

  ldr         r0, =0x3f800000
  vmov.f32    s1, r0
  vadd.f32    s0, s0, s1

  ldr         r0, =0x40600000         @ 3.5
  vmov.f32    s1, r0
  ldr         r0, =player_rolling
  ldr         r0, [r0]
  tst         r0, r0
  vmulne.f32  s0, s0, s1

  ldr         r0, =0x40a00000
  vmov.f32    s1, r0
  vcmp.f32    s0, s1
  fmstat
  vmovgt.f32  s0, s1

  ldr         r0, =player_speed
  vstr.f32    s0, [r0]

  mov         pc, lr

@ ------------------------------------------------------------------------------
@ Increase player's speed modifier
@ ------------------------------------------------------------------------------
do_speed_inc:
  stmfd       sp!, {r0, r1}
  ldr         r0, =player_speed_mod
  ldr         r1, [r0]
  add         r1, r1, #1
  str         r1, [r0]
  ldmfd       sp!, {r0, r1}
  mov         pc, lr

@ ------------------------------------------------------------------------------
@ Updates the position of the player
@ ------------------------------------------------------------------------------
do_movement:
  @ Normal speed
  ldr         r0, =player_rolling
  ldr         r0, [r0]
  tst         r0, r0
  movne       pc, lr

  stmfd       sp!, {lr}

  @ Get button state
  ldr         r2, =button_pressed
  ldr         r2, [r2]

  @ Move player forward
  ldr         r0, =player_pos
  vldm.f32    r0, {s0 - s2}
  ldr         r3, =0x3f800000       @ 1.0
  vmov.f32    s4, r3
  tst         r2, #0x80
  vaddne.f32  s0, s4                @ right
  tst         r2, #0x40
  vsubne.f32  s0, s4                @ left
  tst         r2, #0x10
  vsubne.f32  s1, s4                @ up
  tst         r2, #0x20
  vaddne.f32  s1, s4                @ down
  bl          clamp

  vstm.f32    r0, {s0 - s2}

  @ Tilt left/right
  ldr         r3, =player_tilt_z
  vldr.f32    s0, [r3]
  ldr         r0, =0x3d23d70a       @ 0.04
  vmov.f32    s1, r0

  tst         r2, #0x80
  beq         1f
  vsub.f32    s0, s1
  ldr         r0, =0xbecccccd       @ -0.4
  vmov.f32    s2, r0
  vcmp.f32    s0, s2
  fmstat
  vmovlt.f32  s0, s2
  b           4f
1:
  tst         r2, #0x40
  beq         2f
  vadd.f32    s0, s1
  ldr         r0, =0x3ecccccd       @ 0.4
  vmov.f32    s2, r0
  vcmp.f32    s0, s2
  fmstat
  vmovgt.f32  s0, s2
  b           4f
2:
  vcmp.f32    s0, #0
  fmstat
  blt         3f
  vsub.f32    s0, s1
  ldr         r0, =0
  vmov.f32    s2, r0
  vcmp.f32    s0, s2
  fmstat
  vmovlt.f32  s0, s2
  b           4f
3:
  vadd.f32    s0, s1
  ldr         r0, =0
  vmov.f32    s2, r0
  vcmp.f32    s0, s2
  fmstat
  vmovgt.f32  s0, s2
4:
  vstr.f32    s0, [r3]

  @ Tilt up/down
  ldr         r3, =player_tilt_x
  vldr.f32    s0, [r3]
  ldr         r0, =0x3d23d70a       @ 0.04
  vmov.f32    s1, r0

  tst         r2, #0x20
  beq         1f
  vsub.f32    s0, s1
  ldr         r0, =0xbecccccd       @ -0.4
  vmov.f32    s2, r0
  vcmp.f32    s0, s2
  fmstat
  vmovlt.f32  s0, s2
  b           4f
1:
  tst         r2, #0x10
  beq         2f
  vadd.f32    s0, s1
  ldr         r0, =0x3dcccccd       @ 0.1
  vmov.f32    s2, r0
  vcmp.f32    s0, s2
  fmstat
  vmovgt.f32  s0, s2
  b           4f
2:
  vcmp.f32    s0, #0
  fmstat
  blt         3f
  vsub.f32    s0, s1
  ldr         r0, =0
  vmov.f32    s2, r0
  vcmp.f32    s0, s2
  fmstat
  vmovlt.f32  s0, s2
  b           4f
3:
  vadd.f32    s0, s1
  ldr         r0, =0
  vmov.f32    s2, r0
  vcmp.f32    s0, s2
  fmstat
  vmovgt.f32  s0, s2
4:
  vstr.f32    s0, [r3]

  ldmfd       sp!, {pc}

@-------------------------------------------------------------------------------
@ Handles repairs
@-------------------------------------------------------------------------------
do_repair:
  @ Repair when B was double clicked
  ldr         r0, =button_dclicked
  ldr         r0, [r0]
  tst         r0, #0x02
  moveq       pc, lr

  @ Check number of repairs left
  ldr         r0, =player_wrenches
  ldr         r1, [r0]
  tst         r1, r1
  moveq       pc, lr
  sub         r1, #1
  str         r1, [r0]

  @ Update health
  ldr         r0, =player_health
  ldr         r1, [r0]
  add         r1, #50
  cmp         r1, #200
  movgt       r1, #200
  str         r1, [r0]

  mov         pc, lr

@-------------------------------------------------------------------------------
@ Handles firing rockets
@-------------------------------------------------------------------------------
do_rocket:
  stmfd       sp!, {lr}

  @ Fire when B was clicked
  ldr         r0, =button_clicked
  ldr         r1, [r0]
  tst         r1, #0x02
  moveq       pc, lr

  @ Check number of rockets left
  ldr         r0, =player_rockets
  ldr         r1, [r0]
  tst         r1, r1
  moveq       pc, lr
  sub         r1, #1
  str         r1, [r0]

  @ Play rocket sound
  bl          snd_play_rocket

  @ Fire the rocket
  bl          spawn_rocket

  ldmfd       sp!, {pc}

@-------------------------------------------------------------------------------
@ Increses the charge of barrell roll
@-------------------------------------------------------------------------------
do_charge:
  @ Check for roll
  ldr         r0, =player_rolling
  ldr         r0, [r0]
  tst         r0, r0
  movne       pc, lr

  @ Update charge
  ldr         r0, =player_charge
  ldr         r1, [r0]
  cmp         r1, #200
  add         r1, #1
  strlt       r1, [r0]

  mov         pc, lr

@ ------------------------------------------------------------------------------
@ Computes mtx_view and mtx_vp
@ ------------------------------------------------------------------------------
do_matrices:
  stmfd       sp!, {lr}

  @ Clear the view matrix
  ldr         r0, =mtx_id
  vldm.f32    r0, {s0 - s15}
  ldr         r0, =mtx_view
  vstm.f32    r0, {s0 - s15}

  @ Shake the world
  ldr         r0, =player_shake
  ldr         r1, [r0]
  tst         r1, r1
  subne       r1, r1, #1
  str         r1, [r0]
  vmov.f32    s0, r1
  fsitos      s0, s0
  bl          sin
  ldr         r0, =0x42700000
  vmov.f32    s2, r0
  vmul.f32    s5, s0, s1
  vdiv.f32    s5, s5, s2

  @ Compute the view matrix (translation)
  ldr         r0, =player_pos
  vldm.f32    r0, {s0 - s2}
  vadd.f32    s1, s1, s5
  vabs.f32    s5, s5
  vsub.f32    s0, s5, s0
  ldr         r0, =mtx_view
  bl          mat4_translate

  @ Compute the proj * view matrix
  ldr         r0, =mtx_proj
  ldr         r1, =mtx_view
  ldr         r2, =mtx_vp
  bl          mat4_mul_mat4

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Clamps a coordinate, forcing it inside bounds on X and Y axis
@
@ Arguments:
@   s0 - x
@   s1 - y
@   s2 - z
@ Returns:
@   s0 - clamped x
@   s1 - clamped y
@   s2 - clamped z
@ Clobbers
@   none
@ ------------------------------------------------------------------------------
clamp:
  stmfd         sp!, {r0}
  vstmdb.f32    sp!, {s3}

  ldr           r0, =0x41080000     @ 8.5
  vmov.f32      s3, r0
  vcmp.f32      s0, s3
  fmstat
  vmovgt.f32    s0, s3

  ldr           r0, =0xc1080000     @ -8.5
  vmov.f32      s3, r0
  vcmp.f32      s0, s3
  fmstat
  vmovlt.f32    s0, s3

  ldr           r0, =0x3f000000     @ 0.5
  vmov.f32      s3, r0
  vcmp.f32      s1, s3
  fmstat
  vmovgt.f32    s1, s3

  ldr           r0, =0xc0900000     @ -4.5
  vmov.f32      s3, r0
  vcmp.f32      s1, s3
  fmstat
  vmovlt.f32    s1, s3

  vldmia.f32    sp!, {s3}
  ldmfd         sp!, {r0}
  mov           pc, lr

@-------------------------------------------------------------------------------
@ Draws health / charge bar
@
@ Arguments:
@   r0 - x
@   r1 - y
@   r5 - current amount address
@   r6 - colour
@ Returns:
@   none
@ Clobbers:
@   none
@-------------------------------------------------------------------------------
draw_bar:
  stmfd       sp!, {r0 - r6, lr}

  @ Draw frame
  mov         r2, #108
  mov         r3, #20
  ldr         r4, =0xFFFFFF00
  bl          gfx_draw_frame

  @ Draw current charge
  add         r0, #4
  add         r1, #4
  ldr         r2, [r5]
  lsr         r2, r2, #1
  sub         r3, r3, #8
  mov         r4, r6
  bl          gfx_draw_rect

  ldmfd       sp!, {r0 - r6, pc}

@-------------------------------------------------------------------------------
@ Draws character
@ Arguments:
@   r0 - x
@   r1 - y
@   r5 - picture address
@   r6 - message address
@ Returns:
@   none
@ Clobbers:
@   none
@-------------------------------------------------------------------------------
draw_pop_up:
  stmfd       sp!, {r0 - r6, lr}

  @ Draw frame
  mov         r2, #58
  mov         r3, #57
  ldr         r4, =0xFFFFFF00
  bl          gfx_draw_frame

  add         r2, r1, #3
  add         r1, r0, #3
  mov         r0, r5
  bl          gfx_draw_image

  mov         r0, r6
  add         r1, r1, #60
  add         r2, r2, #16
  ldr         r3, =0xFFFFFF00
  bl          printf

  ldmfd       sp!, {r0 - r6, pc}     

@ ------------------------------------------------------------------------------
@ Applies damage to the player
@ Arguments:
@   r0 - damage
@ Returns:
@   none
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
player_damage:
  stmfd       sp!, {r0 - r4, lr}

  ldr         r3, =player_speed_mod     @ Decrement score
  ldr         r4, [r3]
  subs        r4, r4, #300
  movlt       r4, #0
  str         r4, [r3]


  @ Play damage sound
  bl          snd_play_crash

  ldr         r1, =player_health    @ Decrement health
  ldr         r2, [r1]
  cmp         r2, #100
  blt         1f
  sub         r3, r2, r0
  cmp         r3, #100
  bgt         1f

  @ Pop-up Tristan
  ldr         r3, =tristan_timer
  mov         r4, #110
  str         r4, [r3]

  bl          snd_play_roll


1:
  sub         r2, r2, r0
  cmp         r2, #0
  movle       r2, #0
  str         r2, [r1]

  ldr         r1, =player_shake
  mov         r2, #40
  str         r2, [r1]

  ldmfd       sp!, {r0 - r4, pc}

@-------------------------------------------------------------------------------
@ Resets player movement
@-------------------------------------------------------------------------------
reset_player_mov:
  stmfd       sp!, {r0 -r1, lr}
  vstmdb.f32  sp!, {s0}

  mov         r0, #0
  vmov.f32    s0, r0

  ldr         r1, =player_tilt_z
  vstm.f32    r1, {s0}

  ldr         r1, =player_tilt_x
  vstm.f32    r1, {s0}    

  ldr         r1, =player_rolling
  str         r0, [r1]

  ldr         r1, =player_shake
  str         r0, [r1]

  ldr         r1, =player_speed
  vstm.f32    r1, {s0}

  ldr         r1, =player_roll_dir
  ldr         r0, =0x3E19999A         @ 0.15
  vmov.f32    s0, r0
  vstm.f32    r1, {s0}

  vldmia.f32  sp!, {s0}  
  ldmfd       sp!, {r0 - r1, pc}
  
