@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global draw_pillars
.global pillar_pos

.section .data
.include "assets/pillar.s"

.section .text
@ ------------------------------------------------------------------------------
@ Cubes on the sides
@ ------------------------------------------------------------------------------
.equ             PILLAR_COUNT, 24
pillar_pos:     .float 0.0
pillar_list:
  .float        -10.0,  0.0, -142.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0, -130.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0, -118.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0, -106.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0,  -94.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0,  -82.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0,  -70.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0,  -58.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0,  -46.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0,  -34.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0,  -22.0
  .float          1.0,  6.0,    1.0
  .float        -10.0,  0.0,  -10.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0, -142.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0, -130.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0, -118.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0, -106.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0,  -94.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0,  -82.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0,  -70.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0,  -58.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0,  -46.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0,  -34.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0,  -22.0
  .float          1.0,  6.0,    1.0
  .float         10.0,  0.0,  -10.0
  .float          1.0,  6.0,    1.0

@ ------------------------------------------------------------------------------
@ Renders the pillars on the sides
@ ------------------------------------------------------------------------------
draw_pillars:
  stmfd       sp!, {lr}
  ldr         r12, =PILLAR_COUNT
  ldr         r11, =pillar_list

  @ Reset model matrix
  ldr         r0, =mtx_id
  vldm.f32    r0, {s0 - s15}
  ldr         r0, =mtx_model
  vstm.f32    r0, {s0 - s15}

  @ Get player position
  ldr         r0, =player_speed
  vldr.f32    s3, [r0]
  ldr         r0, =pillar_pos
  vldr.f32    s4, [r0]
  vadd.f32    s4, s4, s3
  ldr         r1, =0x41400000
  vmov.f32    s5, r1
  vcmp.f32    s4, s5
  fmstat
  ldr         r1, =0x00000000
  vmovgt.f32  s4, r1
  vstr.f32    s4, [r0]

1:
  vldm.f32    r11!, {s0 - s2}
  vstmdb.f32  sp!, {s4}
  vadd.f32    s2, s2, s4
  bl          draw_pillar
  vldmia.f32  sp!, {s4}
  subs        r12, r12, #1
  bne         1b

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Draws a single pillar
@ ------------------------------------------------------------------------------
draw_pillar:
  stmfd       sp!, {lr}

  ldr         r0, =mtx_model
  bl          mat4_translate
  vldm.f32    r11!, {s0 - s2}
  bl          mat4_scale

  ldr         r0, =mtx_vp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_mvp
  bl          mat4_mul_mat4

  ldr         r0, =pillar_vtx
  ldr         r1, =pillar_idx
  ldr         r2, =10
  ldr         r3, =mtx_mvp
  ldr         r4, =light_dir
  bl          gfx_draw_trgs

  ldmfd       sp!, {pc}
