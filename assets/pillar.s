@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global pillar_vtx
.global pillar_idx

@ ------------------------------------------------------------------------------
@ Cube model
@ X Y Z 1.0
@ ------------------------------------------------------------------------------
.align 2
pillar_vtx:
  @ Front
  .float -0.5, -0.5,  0.5,  1.0
  .float  0.5, -0.5,  0.5,  1.0
  .float  0.5,  0.5,  0.5,  1.0
  .float -0.5,  0.5,  0.5,  1.0
  @ Back
  .float -0.5, -0.5, -0.5,  1.0
  .float  0.5, -0.5, -0.5,  1.0
  .float  0.5,  0.5, -0.5,  1.0
  .float -0.5,  0.5, -0.5,  1.0
  @ Top
  .float  0.5,  0.5, -0.5,  1.0
  .float -0.5,  0.5, -0.5,  1.0
  .float -0.5,  0.5,  0.5,  1.0
  .float  0.5,  0.5,  0.5,  1.0
  @ Left
  .float  0.5, -0.5, -0.5,  1.0
  .float  0.5,  0.5, -0.5,  1.0
  .float  0.5,  0.5,  0.5,  1.0
  .float  0.5, -0.5,  0.5,  1.0
  @ Right
  .float -0.5,  0.5, -0.5,  1.0
  .float -0.5, -0.5, -0.5,  1.0
  .float -0.5, -0.5,  0.5,  1.0
  .float -0.5,  0.5,  0.5,  1.0

pillar_idx:
  .long 0, 1, 3
  .float 0.5, 0.5, 0.5
  .long 3, 1, 2
  .float 0.5, 0.5, 0.5

  .long 4, 7, 5
  .float 0.5, 0.5, 0.5
  .long 7, 6, 5
  .float 0.5, 0.5, 0.5

  .long 8, 9, 11
  .float 0.5, 0.5, 0.5
  .long 11, 9, 10
  .float 0.5, 0.5, 0.5

  .long 12, 13, 15
  .float 0.5, 0.5, 0.5
  .long 15, 13, 14
  .float 0.5, 0.5, 0.5

  .long 16, 17, 19
  .float 0.5, 0.5, 0.5
  .long 19, 17, 18
  .float 0.5, 0.5, 0.5

