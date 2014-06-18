@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global rock_vtx
.global rock_idx

@ ------------------------------------------------------------------------------
@ Rock model
@ X Y Z 1.0
@ ------------------------------------------------------------------------------
.align 2
rock_vtx:
  .float  0.0,    0.75,    1.2135,  1.0
  .float  0.0,    0.75,   -1.2135,  1.0
  .float  0.0,   -0.75,    1.2135,  1.0
  .float  0.0,   -0.75,   -1.2135,  1.0
  .float  0.75,    1.2135,  0.0,    1.0
  .float  0.75,   -1.2135,  0.0,    1.0
  .float -0.75,    1.2135,  0.0,    1.0
  .float -0.75,   -1.2135,  0.0,    1.0
  .float  1.2135,  0.0,    0.75,    1.0
  .float  1.2135,  0.0,   -0.75,    1.0
  .float -1.2135,  0.0,    0.75,    1.0
  .float -1.2135,  0.0,   -0.75,    1.0

rock_idx:
  .long 0, 2, 8
  .float 0.9, 0.2, 0.2
  .long 10, 2, 0
  .float 0.9, 0.2, 0.2
  .long 0, 4, 6
  .float 0.9, 0.2, 0.2
  .long 8, 4, 0
  .float 0.9, 0.2, 0.2
  .long 0, 6, 10
  .float 0.9, 0.2, 0.2
  .long 1, 9, 3
  .float 0.9, 0.2, 0.2
  .long 11, 1, 3
  .float 0.9, 0.2, 0.2
  .long 4, 1, 6
  .float 0.9, 0.2, 0.2
  .long 9, 1, 4
  .float 0.9, 0.2, 0.2
  .long 6, 1, 11
  .float 0.9, 0.2, 0.2
  .long 2, 7, 5
  .float 0.9, 0.2, 0.2
  .long 5, 8, 2
  .float 0.9, 0.2, 0.2
  .long 10, 7, 2
  .float 0.9, 0.2, 0.2
  .long 7, 3, 5
  .float 0.9, 0.2, 0.2
  .long 3, 9, 5
  .float 0.9, 0.2, 0.2
  .long 11, 3, 7
  .float 0.9, 0.2, 0.2
  .long 4, 8, 9
  .float 0.9, 0.2, 0.2
  .long 5, 9, 8
  .float 0.9, 0.2, 0.2
  .long 11, 10, 6
  .float 0.9, 0.2, 0.2
  .long 10, 11, 7
  .float 0.9, 0.2, 0.2

  .long 0, 2, 8
  .float 0.7, 0.5, 0.5
  .long 10, 2, 0
  .float 0.7, 0.5, 0.5
  .long 0, 4, 6
  .float 0.7, 0.5, 0.5
  .long 8, 4, 0
  .float 0.7, 0.5, 0.5
  .long 0, 6, 10
  .float 0.7, 0.5, 0.5
  .long 1, 9, 3
  .float 0.7, 0.5, 0.5
  .long 11, 1, 3
  .float 0.7, 0.5, 0.5
  .long 4, 1, 6
  .float 0.7, 0.5, 0.5
  .long 9, 1, 4
  .float 0.7, 0.5, 0.5
  .long 6, 1, 11
  .float 0.7, 0.5, 0.5
  .long 2, 7, 5
  .float 0.7, 0.5, 0.5
  .long 5, 8, 2
  .float 0.7, 0.5, 0.5
  .long 10, 7, 2
  .float 0.7, 0.5, 0.5
  .long 7, 3, 5
  .float 0.7, 0.5, 0.5
  .long 3, 9, 5
  .float 0.7, 0.5, 0.5
  .long 11, 3, 7
  .float 0.7, 0.5, 0.5
  .long 4, 8, 9
  .float 0.7, 0.5, 0.5
  .long 5, 9, 8
  .float 0.7, 0.5, 0.5
  .long 11, 10, 6
  .float 0.7, 0.5, 0.5
  .long 10, 11, 7
  .float 0.7, 0.5, 0.5

  .long 0, 2, 8
  .float 0.5, 0.5, 0.5
  .long 10, 2, 0
  .float 0.5, 0.5, 0.5
  .long 0, 4, 6
  .float 0.5, 0.5, 0.5
  .long 8, 4, 0
  .float 0.5, 0.5, 0.5
  .long 0, 6, 10
  .float 0.5, 0.5, 0.5
  .long 1, 9, 3
  .float 0.5, 0.5, 0.5
  .long 11, 1, 3
  .float 0.5, 0.5, 0.5
  .long 4, 1, 6
  .float 0.5, 0.5, 0.5
  .long 9, 1, 4
  .float 0.5, 0.5, 0.5
  .long 6, 1, 11
  .float 0.5, 0.5, 0.5
  .long 2, 7, 5
  .float 0.5, 0.5, 0.5
  .long 5, 8, 2
  .float 0.5, 0.5, 0.5
  .long 10, 7, 2
  .float 0.5, 0.5, 0.5
  .long 7, 3, 5
  .float 0.5, 0.5, 0.5
  .long 3, 9, 5
  .float 0.5, 0.5, 0.5
  .long 11, 3, 7
  .float 0.5, 0.5, 0.5
  .long 4, 8, 9
  .float 0.5, 0.5, 0.5
  .long 5, 9, 8
  .float 0.5, 0.5, 0.5
  .long 11, 10, 6
  .float 0.5, 0.5, 0.5
  .long 10, 11, 7
  .float 0.5, 0.5, 0.5
