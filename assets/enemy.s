@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global enemy_vtx
.global enemy_idx

@ ------------------------------------------------------------------------------
@ Enemy model
@ X Y Z 1.0
@ ------------------------------------------------------------------------------
.align 2
enemy_vtx:
  .float  0.00,    0.75,    0.0,  1.0 @ 0
  .float -0.75,    0.00,    0.0,  1.0 @ 1
  .float  0.00,   -0.75,    0.0,  1.0 @ 2
  .float  0.75,    0.00,    0.0,  1.0 @ 3

  .float -0.90,    0.90,    0.0,  1.0 @ 4
  .float -0.90,   -0.90,    0.0,  1.0 @ 5
  .float  0.90,   -0.90,    0.0,  1.0 @ 6
  .float  0.90,    0.90,    0.0,  1.0 @ 7

  .float  0.00,    0.00,    2.0,  1.0 @ 8

  .float -0.60,    0.60,    1.0,  1.0 @ 9
  .float -0.60,   -0.60,    1.0,  1.0 @ 10
  .float  0.60,   -0.60,    1.0,  1.0 @ 11
  .float  0.60,    0.60,    1.0,  1.0 @ 12

enemy_idx:
  .long 0, 1, 8
  .float 1.0, 0.2, 0.2
  .long 1, 2, 8
  .float 1.0, 0.2, 0.2
  .long 2, 3, 8
  .float 1.0, 0.2, 0.2
  .long 3, 0, 8
  .float 1.0, 0.2, 0.2

  .long 1, 0, 9
  .float 1.0, 0.7, 0.2
  .long 0, 4, 9
  .float 1.0, 0.7, 0.2
  .long 4, 1, 9
  .float 1.0, 0.7, 0.2

  .long 2, 1, 10
  .float 1.0, 0.7, 0.2
  .long 1, 5, 10
  .float 1.0, 0.7, 0.2
  .long 5, 2, 10
  .float 1.0, 0.7, 0.2

  .long 3, 2, 11
  .float 1.0, 0.7, 0.2
  .long 2, 6, 11
  .float 1.0, 0.7, 0.2
  .long 6, 3, 11
  .float 1.0, 0.7, 0.2

  .long 0, 3, 12
  .float 1.0, 0.7, 0.2
  .long 7, 0, 12
  .float 1.0, 0.7, 0.2
  .long 3, 7, 12
  .float 1.0, 0.7, 0.2

