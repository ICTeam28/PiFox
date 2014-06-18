@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global ship_vtx
.global ship_idx

@ ------------------------------------------------------------------------------
@ Cube model
@ X Y Z 1.0
@ ------------------------------------------------------------------------------
.align 2
ship_vtx:
  @ Center - backside
  .float -0.4,  0.0,  0.0,  1.0
  .float  0.0,  0.2,  0.0,  1.0
  .float  0.4,  0.0,  0.0,  1.0
  .float -0.0, -0.1,  0.0,  1.0
  @ Left - backside
  .float -0.8,  0.0,  0.0,  1.0
  .float -0.6,  0.1,  0.0,  1.0
  .float -0.6, -0.2,  0.0,  1.0
  @ Right - backside
  .float  0.6,  0.1,  0.0,  1.0
  .float  0.8,  0.0,  0.0,  1.0
  .float  0.6, -0.2,  0.0,  1.0
  @ Left tip
  .float -0.6,  0.0, -2.0, 1.0
  @ Center tip
  .float  0.0,  0.0, -3.0, 1.0
  @ Right tip
  .float  0.6,  0.0, -2.0, 1.0
  @ Engine
  .float  0.3,  0.0, -1.0,  1.0
  .float  0.7,  0.5,  0.0,  1.0
  .float -0.3,  0.0, -1.0,  1.0
  .float -0.7,  0.5,  0.0,  1.0

ship_idx:
  .long 1, 0, 2
  .float 0.0, 0.0, 1.0
  .long 0, 3, 2
  .float 0.0, 0.0, 1.0

  .long 5, 4, 0
  .float 1.0, 1.0, 1.0
  .long 0, 4, 6
  .float 1.0, 1.0, 1.0

  .long 7, 2, 8
  .float 1.0, 1.0, 1.0
  .long 8, 2, 9
  .float 1.0, 1.0, 1.0

  .long 10, 4, 5
  .float 1.0, 0.0, 0.0
  .long 10, 6, 4
  .float 1.0, 0.0, 0.0
  .long 10, 5, 0
  .float 1.0, 0.0, 0.0
  .long 10, 0, 6
  .float 1.0, 0.0, 0.0

  .long 11, 0, 1
  .float 1.0, 1.0, 1.0
  .long 11, 3, 0
  .float 1.0, 1.0, 1.0
  .long 11, 1, 2
  .float 1.0, 1.0, 1.0
  .long 11, 2, 3
  .float 1.0, 1.0, 1.0

  .long 12, 2, 7
  .float 1.0, 0.0, 0.0
  .long 12, 9, 2
  .float 1.0, 0.0, 0.0
  .long 12, 7, 8
  .float 1.0, 0.0, 0.0
  .long 12, 8, 9
  .float 1.0, 0.0, 0.0

  .long  14, 13, 2
  .float 0.0, 0.0, 20.0
  .long  14, 2, 13
  .float 0.0, 0.0, 20.0
  .long  16, 0, 15
  .float 0.0, 0.0, 20.0
  .long  16, 15, 0
  .float 0.0, 0.0, 20.0
