@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global draw_rocks
.global reset_objects
.global OBJECT_COUNT
.global object_list

.include "ports.s"

.section .data
@ ------------------------------------------------------------------------------
@ Obstacles
@ ------------------------------------------------------------------------------
.equ             OBJECT_COUNT, 35
.equ             ROCK_LIVES, 3
object_spawn:      .long 0xfffff  @ Frame number of the last spawned rock
object_list:
  .rept OBJECT_COUNT
    .float 0.0, 0.0, 0.0        @ Position (x, y, z)
    .float 1.5                  @ Movement speed
    .float 0.0                  @ Rotation
    .long  0                    @ Type
    .long  ROCK_LIVES           @ Lives
  .endr

.section .text
@ ------------------------------------------------------------------------------
@ Renders the rocks on the sides
@ ------------------------------------------------------------------------------
draw_rocks:
  stmfd       sp!, {lr}

  bl          update_rocks
  bl          sort_objects

  ldr         r12, =OBJECT_COUNT
  ldr         r11, =object_list
1:
  vldm.f32    r11!, {s0 - s6}
  ldr         r0, =0xc1200000     @ -7.0
  vmov.f32    s7, r0
  vcmp.f32    s2, s7
  fmstat
  bllt        draw_object
  subs        r12, r12, #1
  bne         1b

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Updates the position of the rocks
@ ------------------------------------------------------------------------------
update_rocks:
  stmfd       sp!, {lr}

  ldr         r12, =OBJECT_COUNT
  ldr         r11, =object_list

1:
  vldm.f32    r11, {s0 - s6}

  @ Check whether rock is 'live'
  ldr         r0, =0xc1200000
  vmov.f32    s7, r0
  vcmp.f32    s2, s7
  fmstat
  blt         4f

  @ Rock moving out of bound
  ldr         r2, [r11, #8]
  tst         r2, r2
  beq         5f

  @ Clear depth
  mov         r1, #0
  vmov.f32    s2, r1

  @ Test for collision with player
  ldr         r0, =player_pos
  vldm.f32    r0, {s30 - s31}
  vsub.f32    s7, s0, s30
  vabs.f32    s7, s7
  vsub.f32    s8, s1, s31
  ldr         r0, =0x40000000
  vmov.f32    s9, r0
  vsub.f32    s8, s8, s9
  vabs.f32    s8, s8
  ldr         r0, =0x3fe00000
  vmov.f32    s9, r0
  vcmp.f32    s7, s9
  fmstat
  bgt         3f
  vcmp.f32    s8, s9
  fmstat
  bgt         3f

  vmov.f32    r0, s6
  tst         r0, #0x1E
  beq         2f

  @ Decrease health
  ldr         r0, =player_rolling
  ldr         r0, [r0]
  tst         r0, r0
  bne         5f

  mov         r0, #20
  bl          player_damage
  b           5f
2:
  tst         r0, #1
  ldreq       r0, =player_wrenches
  ldrne       r0, =player_rockets
  ldr         r1, [r0]
  add         r1, r1, #1
  cmp         r1, #4
  movge       r1, #3
  str         r1, [r0]
  bllt        snd_play_pickup
  b           5f
3:
  ldr         r0, =player_score     @ Add to score
  ldr         r1, [r0]
  add         r1, r1, #5
  str         r1, [r0]
5:
  @ Spawn a new rock once every 30 frames
  ldr         r0, =object_spawn
  ldr         r1, [r0]
  add         r1, r1, #1
  cmp         r1, #0x20
  movge       r1, #0
  blge        spawn_object
  str         r1, [r0]

  ldr         r0, =enemy_count
  ldr         r0, [r0]
  tst         r0, r0
  movne       r0, #0
  vmovne.f32  s2, r0

  vstm.f32    r11!, {s0 - s6}
  b           5f
4:
  @ Check whether object collided with a bullet
  ldr         r0, =0x40000000
  vmov.f32    s31, r0
  bl          collide_bullets
  tst         r0, r0
  bne         6f

  vmov.f32    r0, s5
  subs        r0, r0, #1
  vmov.f32    s5, r0
  vmoveq      s2, r0
  beq         3b

6:
  @ Updates position
  ldr         r0, =player_speed
  vldr.f32    s9, [r0]
  ldr         r0, =0x3dcccccd
  vmov.f32    s8, r0
  vadd.f32    s2, s2, s3
  vadd.f32    s2, s2, s9
  vmov.f32    r0, s6
  tst         r0, #0x1E
  vaddne.f32  s4, s4, s8
  vstm.f32    r11!, {s0 - s6}
5:
  subs        r12, r12, #1
  bne         1b

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Sorts rocks by their z coordinate
@ ------------------------------------------------------------------------------
sort_objects:
  ldr         r12, =OBJECT_COUNT
  sub         r10, r12, #1
  ldr         r11, =object_list
  ldr         r4,  =28 @ size of rock in bytes

  ldr         r5, =0x0 @ i
1:
  @ outer loop start
  ldr         r6, =0x0 @ j
2:
  @ inner loop start
  @ Calculate address of j and j+1
  mla         r7, r6, r4, r11
  add         r8, r7, r4

  @ Compare Z coordinates
  ldr         r0, [r7, #8]
  vmov.f32    s0, r0
  ldr         r1, [r8, #8]
  vmov.f32    s1, r1
  vcmp.f32    s0, s1
  fmstat
  ble         3f

  @ Swap
  vldm.f32    r7, {s18 - s24}
  vldm.f32    r8, {s25 - s31}
  vstm.f32    r8, {s18 - s24}
  vstm.f32    r7, {s25 - s31}

3: @ inner loop end
  add         r6, r6, #1
  cmp         r6, r10
  blt         2b

4: @ outer loop end
  add         r5, r5, #1
  sub         r10, r10, #1
  cmp         r5, r12
  blt         1b

  mov         pc, lr

@ ------------------------------------------------------------------------------
@ Spawns a new rock
@ Arguments:
@   none
@ Returns:
@   s0 - s4: rock attributes
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
spawn_object:
  stmfd       sp!, {r0 - r1, lr}

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
  ldr         r1, =0x41f00000
  vmov.f32    s9, r1
  vdiv.f32    s1, s8, s9

  @ Set z to -300.0
  ldr         r0, =0xc3960000
  vmov.f32    s2, r0

  @ Reset rotation
  ldr         r0, =0x00000000
  vmov.f32    s4, r0

  @ Randomize type
  bl          random
  and         r0, #0x1F
  vmov.f32    s6, r0

  @ Lives for rocks
  ldr         r0, =ROCK_LIVES
  vmov.f32    s5, r0

  ldmfd       sp!, {r0 - r1, pc}

@ ------------------------------------------------------------------------------
@ Draws an object
@
@ Arguments:
@   s0 - s4: Rock attributes
@ Returns:
@   none
@ Clobbers:
@  s0 - s31
@ Remarks:
@   tail call - called function pops return address from stack
@ ------------------------------------------------------------------------------
draw_object:
  stmfd       sp!, {lr}
  vstmdb.f32  sp!, {s5 - s6}

  @ Reset model matrix
  ldr         r0, =mtx_id
  vldm.f32    r0, {s16 - s31}
  ldr         r0, =mtx_model
  vstm.f32    r0, {s16 - s31}
  ldr         r0, =mtx_temp
  vstm.f32    r0, {s16 - s31}

  @ Translate & rotate
  vneg.f32    s1, s1
  ldr         r0, =mtx_model
  bl          mat4_translate
  vmov.f32    s0, s4
  ldr         r0, =mtx_temp
  bl          mat4_rot_y
  ldr         r0, =mtx_model
  ldr         r1, =mtx_temp
  ldr         r2, =mtx_model
  bl          mat4_mul_mat4

  @ Render the cube
  ldr         r0, =mtx_vp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_mvp
  bl          mat4_mul_mat4

  vldmia.f32  sp!, {s5 - s6}
  vmov.f32    r0, s6
  teq         r0, #0
  beq         draw_wrench_sprite
  teq         r0, #1
  beq         draw_rocket_sprite
  b           draw_rock

@ ------------------------------------------------------------------------------
@ Draws a single rock
@ Arguments:
@   s0 - s4: Rock attributes
@ Returns:
@   none
@ Clobbers:
@  s0 - s31
@ ------------------------------------------------------------------------------
draw_rock:
  vmov.f32    r5, s5
  sub         r5, r5, #1
  ldr         r6, =480

  ldr         r0, =rock_vtx
  ldr         r1, =rock_idx
  mla         r1, r5, r6, r1
  ldr         r2, =20
  ldr         r3, =mtx_mvp
  ldr         r4, =light_dir
  bl          gfx_draw_trgs

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Draws a wrench sprite
@ Arguments:
@   s0 - s4: Rock attributes
@ Returns:
@   none
@ Clobbers:
@  s0 - s31
@ ------------------------------------------------------------------------------
draw_wrench_sprite:
  ldr         r0, =wrench
  ldr         r1, =mtx_mvp
  ldr         r2, =mtx_view
  ldr         r3, =0x3f800000
  vmov.f32    s0, r3
  vmov.f32    s1, r3
  bl          gfx_draw_sprite

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Draws a rocket sprite
@ Arguments:
@   s0 - s4: Rock attributes
@ Returns:
@   none
@ Clobbers:
@  s0 - s31
@ ------------------------------------------------------------------------------
draw_rocket_sprite:
  ldr         r0, =rocket
  ldr         r1, =mtx_mvp
  ldr         r2, =mtx_view
  ldr         r3, =0x3f800000
  vmov.f32    s0, r3
  vmov.f32    s1, r3
  bl          gfx_draw_sprite

  ldmfd       sp!, {pc}

@-------------------------------------------------------------------------------
@ Resets objects
@-------------------------------------------------------------------------------
reset_objects:
  stmfd       sp!, {r0 - r4, lr}
  vstmdb.f32  sp!, {s0 - s6}

  ldr         r4, =OBJECT_COUNT
  ldr         r3, =object_list
  ldr         r2, =ROCK_LIVES
  ldr         r1, =0x3FC00000    @ 1.5
  mov         r0, #0

1:
  vldm.f32    r3, {s0 - s6}

  vmov.f32    s0, r0
  vmov.f32    s1, r0
  vmov.f32    s2, r0
  vmov.f32    s3, r1
  vmov.f32    s4, r0
  vmov.f32    s5, r0
  vmov.f32    s6, r2

  vstm.f32    r3!, {s0 - s6}
  
  subs        r4, #1
  bne         1b

  vldmia.f32  sp!, {s0 - s6}
  ldmfd       sp!, {r0 - r4, pc}
