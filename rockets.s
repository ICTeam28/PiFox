@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global draw_rockets
.global spawn_rocket
.global reset_rockets

.section .data
@-------------------------------------------------------------------------------
@ Rockets
@-------------------------------------------------------------------------------
.equ          ROCKET_COUNT, 5
rocket_list:
  .rept ROCKET_COUNT
    .float 0.0, 0.0, 0.0   @ (x, y, z)
    .float 0.25            @ speed
    .float 0.0             @ rotation
    .long 0                @ active
  .endr

.section .text
@-------------------------------------------------------------------------------
@ Draws rockets
@-------------------------------------------------------------------------------
draw_rockets:
  stmfd       sp!, {lr}

  ldr         r12, =ROCKET_COUNT
  ldr         r11, =rocket_list  
  ldr         r10, =0x40a00000      
  vmov.f32    s31, r10              @ radius = 5

1:
  vldmia.f32  r11!, {s0 - s4}
  ldmia       r11!, {r9}

  tst         r9, r9
  beq         3f

  vmov.f32  s11, s0
  vmov.f32  s12, s1
  vmov.f32  s13, s2
  mov       r0, r9
  bl        collide_objects
  bl        collide_enemies
  mov       r9, r0

  @ Update position
  vsub.f32    s2, s2, s3     

  @ Update rotation
  ldr         r0, =0x3C23D70A       @ r0 = 0.01
  vmov.f32    s5, r0
  vadd.f32    s4, s4, s5

  ldr         r0, =0xc3480000
  vmov.f32    s5, r0                @ s5 = -200  
  vcmp.f32    s2, s5
  fmstat
  movle       r9, #0

3:
  stmdb       r11!, {r9}  
  vstmdb.f32  r11!, {s0 - s4}

  tst         r9, r9 
  blne        draw_rocket
  add         r11, r11, #24
  subs        r12, r12, #1
  bne         1b

  ldmfd       sp!, {pc}

@-------------------------------------------------------------------------------
@ Spawn rocket
@-------------------------------------------------------------------------------
spawn_rocket:
  stmfd       sp!, {lr}

  ldr         r12, =ROCKET_COUNT
  ldr         r11, =rocket_list

1:
  vldmia.f32  r11!, {s0 - s4}
  ldmia       r11!, {r9}

  @ do not overwrite an existing rocket
  tst         r9, r9
  bne         2f

  ldr         r0, =player_pos
  vldmia.f32  r0, {s0 - s2}

  @ set z
  ldr         r0, =0xC1200000       
  vmov.f32    s2, r0                @ z = -10

  @ set y
  ldr         r0, =0xc0000000
  vmov.f32    s5, r0
  vsub.f32    s1, s1, s5            @ y = p.y + 2

  @ set speed
  ldr         r0, =0x3f800000
  vmov.f32    s3, r0                @ speed = 0.25

  @ set rotation
  ldr         r0, =0
  vmov.f32    s4, r0                

  @ activate
  mov         r9, #1

  stmdb       r11!, {r9} 
  vstmdb.f32  r11!, {s0 - s4}
  ldmfd       sp!, {pc}

2:
  stmdb       r11!, {r9} 
  vstmdb.f32  r11!, {s0 - s4}

  add         r11, r11, #24
  subs        r12, r12, #1
  bne         1b

  ldmfd       sp!, {pc}

@-------------------------------------------------------------------------------
@ Draws a single rocket
@ Arguments:
@   s0 - s4: Rocket attributes
@ Returns:
@   none
@ Clobbers:
@   s0 - s31, r0 -r4
@-------------------------------------------------------------------------------
draw_rocket:
  stmfd       sp!, {lr}

  @ Clear model matrix
  ldr         r0, =mtx_id
  vldm.f32    r0, {s16 - s31}
  ldr         r0, =mtx_model
  vstm.f32    r0, {s16 - s31}
  ldr         r0, =mtx_temp
  vstm.f32    r0, {s16 - s31}

  @ Translate
  vneg.f32    s1, s1 
  ldr         r0, =mtx_model
  bl          mat4_translate

  @ Rotate
  vmov.f32   s0, s4            @ s0 = angle
  ldr        r0, =mtx_temp
  bl         mat4_rot_z

  ldr        r0, =mtx_model
  ldr        r1, =mtx_temp
  ldr        r2, =mtx_model
  bl         mat4_mul_mat4

  @ Compute mvp
  ldr        r0, =mtx_vp
  ldr        r1, =mtx_model    @ v' = MVP * v
  ldr        r2, =mtx_mvp      
  bl         mat4_mul_mat4

  ldr        r0, =rocket_vtx
  ldr        r1, =rocket_idx
  ldr        r2, =30
  ldr        r3, =mtx_mvp
  ldr        r4, =light_dir
  bl         gfx_draw_trgs

  ldmfd      sp!, {pc}

@-------------------------------------------------------------------------------
@ Collide rocket at (s11, s12, s13) with all objects
@ Arguments:
@   s11 - x
@   s12 - y
@   s13 - z
@   s31 - radius
@ Returns:
@
@ Clobbers:
@-------------------------------------------------------------------------------
collide_objects:
  stmfd       sp!, {r0 - r12, lr}
  vstmdb.f32  sp!, {s0 - s7}

  ldr         r12, =OBJECT_COUNT
  ldr         r11, =object_list

1:
  vldm.f32    r11, {s0 - s6}  

  @ Check x
  vsub.f32    s7, s11, s0
  vabs.f32    s7, s7
  vcmp.f32    s7, s31
  fmstat
  bgt         2f

  @ Check y
  vsub.f32    s7, s12, s1
  vabs.f32    s7, s7
  vcmp.f32    s7, s31
  fmstat
  bgt         2f

  @ Check z
  vsub.f32    s7, s13, s2
  vabs.f32    s7, s7
  vcmp.f32    s7, s31
  fmstat
  bgt         2f

  @ Cause damage & update score if needed
  vmov.f32    r9, s5
  cmp         r9, #2
  moveq       r9, #0
  movgt       r9, #1
  ldreq       r1, =player_score
  ldreq       r2, [r1]
  addeq       r2, r2, #5
  streq       r2, [r1]
  vmoveq.f32  s2, r9
  vmov.f32    s5, r9

2:
  vstm.f32    r11!, {s0 - s6}
  subs        r12, r12, #1
  bne         1b

  vldmia.f32  sp!, {s0 - s7}
  ldmfd       sp!, {r0 - r12, pc}

@-------------------------------------------------------------------------------
@ Collide rocket at (s11, s12, s13) with all enemies
@ Arguments:
@   s11 - x
@   s12 - y
@   s13 - z
@   s31 - radius
@ Returns:
@   r0 - 0 if collision happened
@ Clobbers:
@-------------------------------------------------------------------------------
collide_enemies:
  stmfd       sp!, {r1 - r12, lr}
  vstmdb.f32  sp!, {s0 - s8}

  ldr         r12, =ENEMY_COUNT
  ldr         r11, =enemies

1:
  vldm.f32    r11, {s0 - s7}  

  @ Check x
  vsub.f32    s8, s11, s0
  vabs.f32    s8, s8
  vcmp.f32    s8, s31
  fmstat
  bgt         2f

  @ Check y
  vsub.f32    s8, s12, s1
  vabs.f32    s8, s8
  vcmp.f32    s8, s31
  fmstat
  bgt         2f

  @ Check z
  vsub.f32    s8, s13, s2
  vabs.f32    s8, s8
  vcmp.f32    s8, s31
  fmstat
  bgt         2f

  @ Cause damage & update score if needed
  vmov.f32    r9, s6
  subs        r9, r9, #2
  movlt       r9, #0
  ldr         r1, =player_score
  ldr         r2, [r1]
  addlt       r2, r2, #50
  addge       r2, r2, #100
  str         r2, [r1]
  vmovle.f32  s2, r9
  vmov.f32    s6, r9
  mov         r0, #0

2:
  vstm.f32    r11!, {s0 - s7}
  subs        r12, r12, #1
  bne         1b

  vldmia.f32  sp!, {s0 - s8}
  ldmfd       sp!, {r1 - r12, pc}

@-------------------------------------------------------------------------------
@ Resets rockets
@-------------------------------------------------------------------------------
reset_rockets:
  stmfd       sp!, {r0 - r3, lr}
  vstmdb.f32  sp!, {s0 - s5}

  ldr         r3, =ROCKET_COUNT
  ldr         r2, =rocket_list
  ldr         r1, =0x3E800000    @ 0.25
  mov         r0, #0

1:
  vldm.f32    r2, {s0 - s5}

  vmov.f32    s0, r0
  vmov.f32    s1, r0
  vmov.f32    s2, r0
  vmov.f32    s3, r1
  vmov.f32    s4, r0
  vmov.f32    s5, r0

  vstm.f32    r2!, {s0 - s5}

  subs        r3, #1
  bne         1b

  vldmia.f32  sp!, {s0 - s5}
  ldmfd       sp!, {r0 - r3, pc}
