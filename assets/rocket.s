@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global rocket_vtx
.global rocket_idx

@-------------------------------------------------------------------------------
@ Rocket model
@ X Y Z 1.0
@-------------------------------------------------------------------------------
.align 2
rocket_vtx:
  @ base
  .float  0.2,   0.0,     0.5,  1.0  @b0
  .float  0.06,  0.19,    0.5,  1.0  @b1
  .float -0.16,  0.1174,  0.5,  1.0  @b2
  .float -0.16, -0.1174,  0.5,  1.0  @b3
  .float  0.06, -0.19,    0.5,  1.0  @b4
  .float  0.0,   0.0,     0.5,  1.0  @b5

  @ top
  .float  0.2,   0.0,    -0.5,  1.0  @t0
  .float  0.06,  0.19,   -0.5,  1.0  @t1
  .float -0.16,  0.1174, -0.5,  1.0  @t2
  .float -0.16, -0.1174, -0.5,  1.0  @t3
  .float  0.06, -0.19,   -0.5,  1.0  @t4
  .float  0.0,   0.0,    -1.5,  1.0  @t5

  @ mid
  .float  0.2,   0.0,     0.0,  1.0  @m0
  .float  0.06,  0.19,    0.0,  1.0  @m1
  .float -0.16,  0.1174,  0.0,  1.0  @m2
  .float -0.16, -0.1174,  0.0,  1.0  @m3
  .float  0.06, -0.19,    0.0,  1.0  @m4

  @ wings
  .float  0.4,   0.0,     0.5,  1.0  @w0
  .float  0.12,  0.38,    0.5,  1.0  @w1
  .float -0.32,  0.2348,  0.5,  1.0  @w2
  .float -0.32, -0.2348,  0.5,  1.0  @w3
  .float  0.12, -0.38,    0.5,  1.0  @w4

rocket_idx:
  @ base
  .long 0, 5, 4
  .float 1.0, 0.4, 0.0
  .long 3, 4, 5
  .float 1.0, 0.4, 0.0
  .long 2, 3, 5
  .float 1.0, 0.4, 0.0
  .long 1, 2, 5
  .float 1.0, 0.4, 0.0
  .long 0, 1, 5
  .float 1.0, 0.4, 0.0

  @ sides
  .long 0, 4, 10
  .float 1.0, 0.0, 0.0
  .long 0, 10, 6
  .float 1.0, 0.0, 0.0

  .long 4, 3, 9  
  .float 1.0, 0.0, 0.0
  .long 4, 9, 10  
  .float 1.0, 0.0, 0.0

  .long 3, 2, 8  
  .float 1.0, 0.0, 0.0
  .long 3, 8, 9  
  .float 1.0, 0.0, 0.0

  .long 2, 1, 7  
  .float 1.0, 0.0, 0.0
  .long 2, 7, 8  
  .float 1.0, 0.0, 0.0

  .long 1, 0, 6  
  .float 1.0, 0.0, 0.0
  .long 1, 6, 7  
  .float 1.0, 0.0, 0.0

  @ top
  .long 6, 10, 11
  .float 1.0, 1.0, 1.0
  .long 10, 9, 11
  .float 1.0, 1.0, 1.0  
  .long 9, 8, 11
  .float 1.0, 1.0, 1.0  
  .long 8, 7, 11
  .float 1.0, 1.0, 1.0  
  .long 7, 6, 11
  .float 1.0, 1.0, 1.0

  @ wings
  .long 0, 17, 12
  .float 1.0, 1.0, 1.0
  .long 1, 18, 13
  .float 1.0, 1.0, 1.0
  .long 2, 19, 14
  .float 1.0, 1.0, 1.0
  .long 3, 20, 15
  .float 1.0, 1.0, 1.0
  .long 4, 21, 16
  .float 1.0, 1.0, 1.0

  .long 17, 0, 12
  .float 1.0, 1.0, 1.0
  .long 18, 1, 13
  .float 1.0, 1.0, 1.0
  .long 19, 2, 14
  .float 1.0, 1.0, 1.0
  .long 20, 3, 15
  .float 1.0, 1.0, 1.0
  .long 21, 4, 16
  .float 1.0, 1.0, 1.0
