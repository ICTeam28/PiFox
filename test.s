@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global run_tests

.section .data
@-------------------------------------------------------------------------------
@ Sin and Cos test cases
@-------------------------------------------------------------------------------
angle_input:
  .float -777.0, -10.0, -6.283, -3.6, -3.1415, -3.0, -2.8, -2.5, -2.2, -2.0
  .float -1.8, -1.57075, -1.047197, -0.785375, -0.5
  .float  0.0
  .float  777.0,  10.0,  6.283,  3.6, 3.1415,  3.0,  2.8,  2.5,  2.2,  2.0
  .float  1.8, 1.57075,  1.047197,  0.785375,  0.5

@-------------------------------------------------------------------------------
@ Sin output destination
@-------------------------------------------------------------------------------
sin_output:
  .float  2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
  .float  2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
  .float  2.0, 2.0, 2.0, 2.0

@-------------------------------------------------------------------------------
@ Cos output destination
@-------------------------------------------------------------------------------
cos_output:
  .float  2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
  .float  2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
  .float  2.0, 2.0, 2.0, 2.0

.section .text
@-------------------------------------------------------------------------------
@ Runs test functions
@ Arguments:
@   None
@ Returns:
@   None
@ Clobbers:
@   None
@-------------------------------------------------------------------------------
run_tests:
  stmfd       sp!, {r0 - r2, lr}

  @ test sin
  ldr         r0, =angle_input
  mov         r1, #30
  ldr         r2, =sin_output
  bl          sin_test

  @ test cos
  ldr         r0, =angle_input
  mov         r1, #30
  ldr         r2, =cos_output
  bl          cos_test

  ldmfd       sp!, {r0 - r2, pc}

@ ------------------------------------------------------------------------------
@ Sin function test
@ Arguments:
@   r0 - address of inputs
@   r1 - number of inputs
@   r2 - destination for outputs
@ Returns:
@  None
@ Clobbers:
@  None
@ ------------------------------------------------------------------------------
sin_test:
  stmfd       sp!, {r0 - r4, lr}
  vstmdb      sp!, {s0 - s1}
  mov         r3, #0

1:
  cmp         r3, r1
  bge         2f

  ldr         r4, [r0]
  vmov.f32    s0, r4
  bl          sin
  vstm.f32    r2, {s1}

  add         r0, r0, #4
  add         r2, r2, #4
  add         r3, r3, #1
  b           1b

2:
  vldmia.f32  sp!, {s0 - s1}
  ldmfd       sp!, {r0 - r4, pc}

@ ------------------------------------------------------------------------------
@ Cos function test
@ Arguments:
@   r0 - address of inputs
@   r1 - number of inputs
@   r2 - destination for outputs
@ Returns:
@  None
@ Clobbers:
@  None
@ ------------------------------------------------------------------------------
cos_test:
  stmfd       sp!, {r0 - r4, lr}
  vstmdb      sp!, {s0 - s1}
  mov         r3, #0

1:
  cmp         r3, r1
  bge         2f

  ldr         r4, [r0]
  vmov.f32    s0, r4
  bl          cos
  vstm.f32    r2, {s1}

  add         r0, r0, #4
  add         r2, r2, #4
  add         r3, r3, #1
  b           1b

2:
  vldmia.f32  sp!, {s0 - s1}
  ldmfd       sp!, {r0 - r4, pc}
