@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global sin
.global cos
.global extract_frustum
.global mat4_mul_mat4
.global mat4_mul_vec4
.global mat4_fmul_vec4
.global mat4_view
.global mat4_translate
.global mat4_scale
.global mat4_rot_x
.global mat4_rot_y
.global mat4_rot_z
.global vec4_add
.global vec4_sub
.global vec4_len
.global vec4_norm
.global vec4_dot
.global vec4_cross
.global random
.global fmod

.section .text
@ ------------------------------------------------------------------------------
@ s1 = sin(s0)
@ Approximation of sine
@ Arguments:
@   s0 - angle in radians
@ Returns:
@   s1 - sine of angle
@ Clobbers:
@   None
@ ------------------------------------------------------------------------------
sin:
  stmfd         sp!, {r0}
  vstmdb.f32    sp!, {s2 - s6}

  ldr           r0, =0x40490FDB
  vmov.f32      s4, r0            @ s4 = pi
  ldr           r0, =0x40C90FDB
  vadd.f32      s2, s0, s4        @ s2 = angle + pi = x
  vmov.f32      s3, r0            @ s3 = 2 * pi = y

  @ compute (angle + pi) % 2pi;
  vdiv.f32      s5, s2, s3        @ s5 = x / y
  vcvt.s32.f32  s5, s5
  vcvt.f32.s32  s5, s5            @ s5 = floor(x/y)
  vmls.f32      s2, s3, s5        @ s2 =  x - y * floor(x/y) = m
  mov           r0, #0

  vcmp.f32      s2, s3
  fmstat
  vmovge.f32    s2, r0
  bge           2f
1:@ m < y
  vcmp.f32      s2, #0
  fmstat
  bge           2f                @ s2 = m
  @ m < 0
  vadd.f32      s2, s2, s3        @ m = m + y
  vcmp.f32      s2, s3
  fmstat
  vmoveq.f32    s2, r0
2:
  vsub.f32      s6, s2, s4        @ s6 = ((angle + pi) % 2pi) - pi
  ldr           r0, =0x3fa2f983   @ 4 / pi
  vmov.f32      s1, r0
  vmul.f32      s1, s6            @ s1 = 4 / pi * x

  vcmp.f32      s6, #0            @ sin(0) = 0
  fmstat
  beq           3f

  ldr           r0, =0x3ecf817b   @ 4 / pi ^ 2
  vmov.f32      s2, r0
  vmul.f32      s2, s2, s6
  vmul.f32      s2, s2, s6
  vmul.f32      s2, s2, s6        @ s2 = (4 * x * x * x) / pi ^ 2
  vabs.f32      s3, s6
  vdiv.f32      s2, s2, s3
  vsub.f32      s1, s1, s2
3:
  vldmia.f32    sp!, {s2 - s6}
  ldmfd         sp!, {r0}
  mov           pc, lr

@ ------------------------------------------------------------------------------
@ s1 = cos(s0)
@ Approximation of cos using sin(x) = cos(pi/2 - x)
@ Arguments:
@   s0 - angle in radians
@ Returns:
@   s1 - sine of angle
@ Clobbers:
@   None
@ ------------------------------------------------------------------------------
cos:
  stmfd         sp!, {r0}
  vstmdb.f32    sp!, {s2 - s6}

  ldr           r0, =0x3FC90FDB
  vmov.f32      s4, r0            @ s4 = pi/2
  vsub.f32      s6, s4, s0        @ angle = pi/2 - angle

  ldr           r0, =0x40490FDB
  vmov.f32      s4, r0            @ s4 = pi
  ldr           r0, =0x40C90FDB
  vadd.f32      s2, s6, s4        @ s2 = angle + pi = x
  vmov.f32      s3, r0            @ s3 = 2 * pi = y

  @ compute (angle + pi) % 2pi;
  vdiv.f32      s5, s2, s3        @ s5 = x / y
  vcvt.s32.f32  s5, s5
  vcvt.f32.s32  s5, s5            @ s5 = floor(x/y)
  vmls.f32      s2, s3, s5        @ s2 =  x - y * floor(x/y) = m
  mov           r0, #0

  vcmp.f32      s2, s3
  fmstat
  blt           1f
  vmov.f32      s2, r0            @ s2 = 0
  b             2f
1: @ m < y
  vcmp.f32      s2, #0
  fmstat
  bge           2f                @ s2 = m
  @ m < 0
  vadd.f32      s2, s2, s3        @ m = m + y
  vcmp.f32      s2, s3
  fmstat
  vmoveq.f32    s2, r0
2:
  vsub.f32      s6, s2, s4        @ s6 = ((angle + pi) % 2pi) - pi
  ldr           r0, =0x3fa2f983   @ 4 / pi
  vmov.f32      s1, r0
  vmul.f32      s1, s6            @ s1 = 4 / pi * x

  vcmp.f32      s6, #0
  fmstat
  beq           3f

  ldr           r0, =0x3ecf817b   @ 4 / pi ^ 2
  vmov.f32      s2, r0
  vmul.f32      s2, s2, s6
  vmul.f32      s2, s2, s6
  vmul.f32      s2, s2, s6        @ s2 = (4 * x * x * x) / pi ^ 2
  vabs.f32      s3, s6
  vdiv.f32      s2, s2, s3
  vsub.f32      s1, s1, s2
3:
  vldmia.f32    sp!, {s2 - s6}
  ldmfd         sp!, {r0}
  mov           pc, lr

@ ------------------------------------------------------------------------------
@ Multiplies two matrices together
@ r2 = r1 * r0
@ Arguments:
@   r0 - location of first matrix
@   r1 - location of second matrix
@   r2 - output matrix address
@ Return values:
@   none
@ Clobbers:
@   s0 - s23
@ ------------------------------------------------------------------------------
mat4_mul_mat4:
  stmfd     sp!, {r3, r4}

  vldm.f32  r0, {s0 - s15}

  mov       r4, #4
1:
  vldm.f32  r1!, {s16 - s19}

  vmul.f32  s20,  s0, s16
  vmla.f32  s20,  s4, s17
  vmla.f32  s20,  s8, s18
  vmla.f32  s20, s12, s19

  vmul.f32  s21,  s1, s16
  vmla.f32  s21,  s5, s17
  vmla.f32  s21,  s9, s18
  vmla.f32  s21, s13, s19

  vmul.f32  s22,  s2, s16
  vmla.f32  s22,  s6, s17
  vmla.f32  s22, s10, s18
  vmla.f32  s22, s14, s19

  vmul.f32  s23,  s3, s16
  vmla.f32  s23,  s7, s17
  vmla.f32  s23, s11, s18
  vmla.f32  s23, s15, s19

  vstm.f32  r2!, {s20 - s23}

  subs      r4, #1
  bne       1b

  @ Restore pointers
  sub       r1, #64
  sub       r2, #64

  ldmfd     sp!, {r3, r4}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Multiplies a matrix with a vector
@ Arguments:
@   r0 - location of the matrix
@   r1 - location of the vector
@   r2 - output vector address
@ Returns:
@   none
@ Clobbers:
@   s0 - s19
@ ------------------------------------------------------------------------------
mat4_mul_vec4:
  vldm.f32  r0, {s0 - s15}
  vldm.f32  r1, {s16 - s19}

  vmul.f32  s20,  s0, s16
  vmul.f32  s21,  s1, s16
  vmul.f32  s22,  s2, s16
  vmul.f32  s23,  s3, s16
  vmla.f32  s20,  s4, s17
  vmla.f32  s21,  s5, s17
  vmla.f32  s22,  s6, s17
  vmla.f32  s23,  s7, s17
  vmla.f32  s20,  s8, s18
  vmla.f32  s21,  s9, s18
  vmla.f32  s22, s10, s18
  vmla.f32  s23, s11, s18
  vmla.f32  s20, s12, s19
  vmla.f32  s21, s13, s19
  vmla.f32  s22, s14, s19
  vmla.f32  s23, s15, s19

  vstm.f32  r2, {s20 - s23}

  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Multiplies a matrix with a vector in registers
@ Arguments:
@    s0 - s15: matrix
@   s16 - s19: vector
@   s20 - s23: output
@ Returns:
@   none
@ Clobbers:
@   s0 - s19
@ ------------------------------------------------------------------------------
mat4_fmul_vec4:
  vmul.f32  s20,  s0, s16
  vmul.f32  s21,  s1, s16
  vmul.f32  s22,  s2, s16
  vmul.f32  s23,  s3, s16
  vmla.f32  s20,  s4, s17
  vmla.f32  s21,  s5, s17
  vmla.f32  s22,  s6, s17
  vmla.f32  s23,  s7, s17
  vmla.f32  s20,  s8, s18
  vmla.f32  s21,  s9, s18
  vmla.f32  s22, s10, s18
  vmla.f32  s23, s11, s18
  vmla.f32  s20, s12, s19
  vmla.f32  s21, s13, s19
  vmla.f32  s22, s14, s19
  vmla.f32  s23, s15, s19
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Computes a view matrix
@ Arguments:
@   r0 - eye
@   r1 - at
@   r2 - up
@   r3 - destination matrix
@ Returns:
@   none
@ Clobbers:
@   s0 - s15
@ ------------------------------------------------------------------------------
mat4_view:
  stmfd     sp!, {r4}

  vldm.f32  r0, {s0 - s3}   @ eye{s0, s1, s2}
  vldm.f32  r1, {s3 - s6}   @ at{s3, s4, s5}
  vldm.f32  r2, {s6 - s9}   @ up{s6, s7, s8}

  @ z{s9, s10, s11} = norm(eye - at)
  vsub.f32  s9, s0, s3
  vsub.f32  s10, s1, s4
  vsub.f32  s11, s2, s5
  vmul.f32  s12, s9, s9
  vmla.f32  s12, s10, s10
  vmla.f32  s12, s11, s11
  vsqrt.f32 s12, s12
  vdiv.f32  s9, s9, s12
  vdiv.f32  s10, s10, s12
  vdiv.f32  s11, s11, s12

  @ x{s3, s4, s5} = norm(cross(up, z))
  vmul.f32  s3, s7, s11
  vmls.f32  s3, s8, s10
  vmul.f32  s4, s8, s9
  vmls.f32  s4, s6, s11
  vmul.f32  s5, s6, s10
  vmls.f32  s5, s7, s9
  vmul.f32  s12, s3, s3
  vmla.f32  s12, s4, s4
  vmla.f32  s12, s5, s5
  vsqrt.f32 s12, s12
  vdiv.f32  s3, s3, s12
  vdiv.f32  s4, s4, s12
  vdiv.f32  s5, s5, s12

  @ y{s6, s7, s8} = cross(z, x)
  vmul.f32  s6, s10, s5
  vmls.f32  s6, s11, s4
  vmul.f32  s7, s11, s3
  vmls.f32  s7, s9, s5
  vmul.f32  s8, s9, s4
  vmls.f32  s8, s10, s3

  mov       r4, #0
  vmov.f32  s15, r4

  @ First column
  vmov.f32  s12, s3
  vmov.f32  s13, s6
  vmov.f32  s14, s9
  vstm.f32  r3!, {s12 - s15}

  @ Second column
  vmov.f32  s12, s4
  vmov.f32  s13, s7
  vmov.f32  s14, s10
  vstm.f32  r3!, {s12 - s15}

  @ Third column
  vmov.f32  s12, s5
  vmov.f32  s13, s8
  vmov.f32  s14, s11
  vstm.f32  r3!, {s12 - s15}

  @ Fourth column
  vmov.f32  s12, s15
  vmls.f32  s12, s0, s3
  vmls.f32  s12, s1, s4
  vmls.f32  s12, s2, s5
  vmov.f32  s13, s15
  vmls.f32  s13, s0, s6
  vmls.f32  s13, s1, s7
  vmls.f32  s13, s2, s8
  vmov.f32  s14, s15
  vmls.f32  s14, s0, s9
  vmls.f32  s14, s1, s10
  vmls.f32  s14, s2, s11
  mov       r4, #0x3f800000
  vmov.f32  s15, r4

  vstm.f32  r3, {s12 - s15}

  sub       r3, r3, #48
  ldmfd     sp!, {r4}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Builds a translation matrix
@ Arguments:
@   r0 - matrix
@   s0 - s3: translation
@ Returns:
@   none
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
mat4_translate:
  vstr.f32    s0, [r0, #48]
  vstr.f32    s1, [r0, #52]
  vstr.f32    s2, [r0, #56]
  mov         pc, lr

@ ------------------------------------------------------------------------------
@ Builds a scaling matrix
@ Arguments:
@   r0 - matrix
@   s0 - s3: translation
@ Returns:
@   none
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
mat4_scale:
  vstr.f32    s0, [r0]
  vstr.f32    s1, [r0, #20]
  vstr.f32    s2, [r0, #40]
  mov         pc, lr


@ ------------------------------------------------------------------------------
@ Creates a rotation matrix around X
@ Arguments:
@   r0 - matrix
@   s0 - angle
@ Returns:
@   none
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
mat4_rot_x:
  stmfd       sp!, {lr}

  bl          sin
  vstr.f32    s1, [r0, #24]
  vneg.f32    s1, s1
  vstr.f32    s1, [r0, #36]
  bl          cos
  vstr.f32    s1, [r0, #20]
  vstr.f32    s1, [r0, #40]

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Creates a rotation matrix
@ Arguments:
@   r0 - matrix
@   s0 - angle
@ Returns:
@   none
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
mat4_rot_y:
  stmfd       sp!, {lr}

  bl          sin
  vstr.f32    s1, [r0, #32]
  vneg.f32    s1, s1
  vstr.f32    s1, [r0, #8]
  bl          cos
  vstr.f32    s1, [r0, #0]
  vstr.f32    s1, [r0, #40]

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Creates a rotation matrix around Z
@ Arguments:
@   r0 - matrix
@   s0 - angle
@ Returns:
@   none
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
mat4_rot_z:
  stmfd       sp!, {lr}

  bl          sin
  vstr.f32    s1, [r0, #4]
  vneg.f32    s1, s1
  vstr.f32    s1, [r0, #16]
  bl          cos
  vstr.f32    s1, [r0, #0]
  vstr.f32    s1, [r0, #20]

  ldmfd       sp!, {pc}

@ ------------------------------------------------------------------------------
@ Computes a 3x3 determinant
@ Arguments:
@   s23 - s31: coefficients
@ Returns:
@   s22 - determinant
@ Clobbers:
@   s21
@ ------------------------------------------------------------------------------
mat3_fdet:
  vmul.f32    s21, s27, s31
  vmls.f32    s21, s28, s30
  vmul.f32    s22, s23, s21

  vmul.f32    s21, s28, s29
  vmls.f32    s21, s26, s31
  vmla.f32    s22, s24, s21

  vmul.f32    s21, s26, s30
  vmls.f32    s21, s27, s29
  vmla.f32    s22, s25, s21

  mov         pc, lr

@ ------------------------------------------------------------------------------
@ Adds two 4D vectors
@ Arguments:
@   r0 - location of first vector
@   r1 - location of second vector
@   r2 - location of destination
@ Return values:
@   None
@ Clobbers:
@   s0 - s11
@ ------------------------------------------------------------------------------
vec4_add:
  vldm.f32  r0, {s0 - s3}
  vldm.f32  r1, {s4 - s7}

  vadd.f32  s8, s0, s4
  vadd.f32  s9, s1, s5
  vadd.f32  s10, s2, s6
  vadd.f32  s11, s3, s7

  vstm.f32  r2, {s8 - s11}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Subtracts a vector from another
@ Arguments:
@   r0 - location of first vector
@   r1 - location of second vector
@   r2 - location of destination
@ Return values:
@   None
@ Clobbers
@   s0 - s11
@ ------------------------------------------------------------------------------
vec4_sub:
  vldm.f32  r0, {s0 - s3}
  vldm.f32  r1, {s4 - s7}

  vsub.f32  s8, s0, s4
  vsub.f32  s9, s1, s5
  vsub.f32  s10, s2, s6
  vsub.f32  s11, s3, s7

  vstm.f32  r2, {s8 - s11}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Computes the length of a vector
@ Arguments:
@   r0 - location of first vector
@ Return values:
@   s0 - length of the vector
@ Clobers:
@   s1 - s3
@ ------------------------------------------------------------------------------
vec4_len:
  vldm.f32  r0, {s0 - s3}

  vmul.f32  s0, s0, s0
  vmla.f32  s0, s1, s1
  vmla.f32  s0, s2, s2
  vsqrt.f32 s0, s0

  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Computes the normalised vector(unit vector) of the given vector
@ Arguments:
@   r0 - location of the vector
@   r1 - location of the destination
@ Return values:
@   None
@ Clobbers
@   s0 - s4
@ ------------------------------------------------------------------------------
vec4_norm:
  vldm.f32  r0, {s0 - s3}

  vmul.f32  s4, s0, s0
  vmla.f32  s4, s1, s2
  vmla.f32  s4, s2, s2
  vsqrt.f32 s4, s4      @ s4 = |v|

  vdiv.f32  s0, s0, s4
  vdiv.f32  s1, s1, s4
  vdiv.f32  s2, s2, s4

  vstm.f32  r1, {s0 - s3}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Computes the dot product of two vectors
@ Arguments:
@   r0 - location of the first vector
@   r1 - location of the second vector
@ Return values:
@   s0 - dot product
@ Clobbers
@   s0 - s6
@ ------------------------------------------------------------------------------
vec4_dot:
  vldm.f32  r0, {s1 - s3}
  vldm.f32  r1, {s4 - s6}

  vmul.f32  s0, s1, s4
  vmla.f32  s0, s2, s5
  vmla.f32  s0, s3, s6

  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Computes the cross product of two vectors
@ Arguments:
@   r0 - location of the first vector
@   r1 - location of the second vector
@   r2 - location of the destination
@ Return values:
@   None
@ Clobbers:
@   s0 - s10
@ ------------------------------------------------------------------------------
vec4_cross:
  stmfd     sp!, {r3}

  vldm.f32  r0, {s0 - s3}        @ s0 = x1; s1 = y1; s2 = z1
  vldm.f32  r1, {s3 - s6}        @ s3 = x2; s4 = y2; s5 = z2

  vmul.f32  s6, s1, s5           @ s6 = y1 * z2
  vmls.f32  s6, s4, s2           @ s6 = s6 - (y2 * z1)
  vmul.f32  s7, s3, s2           @ s7 = x2 * z1
  vmls.f32  s7, s0, s5           @ s7 = s7 - (x1 * z2)
  vmul.f32  s8, s0, s4           @ s8 = x1 * y2
  vmls.f32  s8, s1, s3           @ s8 = s8 - (x2 * y1)

  mov       r3, #0
  vmov.f32  s9, r3

  vstm.f32  r2, {s6 - s9}

  ldmfd     sp!, {r3}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Floating point modulo
@ Arguments:
@   s0 - x
@   s1 - y
@ Returns:
@   s2 - x % y
@ Clobbers:
@   None
@ ------------------------------------------------------------------------------
fmod:
  stmfd         sp!, {r0}
  vstmdb.f32    sp!, {s3}

  vcmp.f32      s1, #0
  fmstat
  beq           4f

  mov           r0, #0
  vdiv.f32      s3, s0, s1        @ s3 = x / y
  vcvt.s32.f32  s3, s3
  vcvt.f32.s32  s3, s3            @ s3 = floor(x/y)
  vmls.f32      s0, s1, s3        @ s0 = x - y * floor(x/y) = m

  vcmp.f32      s1, #0
  fmstat
  ble           2f
  vcmp.f32      s0, s1
  fmstat
  blt           1f
  vmov.f32      s0, r0
  b             4f                @ s0 = 0
1:
  vcmp.f32      s0, #0
  fmstat
  bge           4f                @ s0 = m
  vadd.f32      s0, s0, s1        @ s0 = m + y
  vcmp.f32      s0, s1
  vmoveq.f32    s0, r0            @ s0 = 0
  b             4f
2:
  vcmp.f32      s0, s1
  fmstat
  bgt           3f
  vmov.f32      s0, r0
  b             4f                @ s0 = 0
3:
  vcmp.f32      s0, #0
  fmstat
  ble           4f                @ s0 = m
  vadd.f32      s0, s0, s1        @ s0 = m + y
  vcmp.f32      s0, s1
  fmstat
  vmoveq.f32    s0, r0            @ s0 = 0
4:
  vmov.f32      s2, s0            @ s2 = s0

  vldmia.f32    sp!, {s3}
  ldmfd         sp!, {r0}
  mov           pc, lr

@ ------------------------------------------------------------------------------
@ Computes the intersection point of three planes using Kramer's rule
@ Arguments:
@   s0 - s3: (a1, b1, c1, d1)
@   s4 - s7: (a1, b1, c1, d1)
@   s8 - s11: (a1, b1, c1, d1)
@ Returns:
@   s12 - s14: (x, y, z)
@ Clobbers:
@   s15, s22 - s31
@ ------------------------------------------------------------------------------
insersect_planes:
  mov       r11, lr

  vmov.f32  s23, s0
  vmov.f32  s24, s4
  vmov.f32  s25, s8
  vmov.f32  s26, s1
  vmov.f32  s27, s5
  vmov.f32  s28, s9
  vmov.f32  s29, s2
  vmov.f32  s30, s6
  vmov.f32  s31, s10
  bl        mat3_fdet
  vmov.f32  s15, s22          @ det

  vmov.f32  s23, s3
  vmov.f32  s24, s7
  vmov.f32  s25, s11
  bl        mat3_fdet
  vdiv.f32  s12, s22, s15     @ x
  vneg.f32  s12, s12

  vmov.f32  s23, s0
  vmov.f32  s24, s4
  vmov.f32  s25, s8
  vmov.f32  s26, s3
  vmov.f32  s27, s7
  vmov.f32  s28, s11
  bl        mat3_fdet
  vdiv.f32  s13, s22, s15     @ y
  vneg.f32  s13, s13

  vmov.f32  s26, s1
  vmov.f32  s27, s5
  vmov.f32  s28, s9
  vmov.f32  s29, s3
  vmov.f32  s30, s7
  vmov.f32  s31, s11
  bl        mat3_fdet
  vdiv.f32  s14, s22, s15    @ z
  vneg.f32  s14, s14

  mov       pc, r11

@ ------------------------------------------------------------------------------
@ Extracts clip planes from a view-projection matrix
@ Arguments:
@   r0 - matrix
@   r1 - frustum
@ Returns:
@   8 vertices on the stack
@ Clobbers:
@   s0 - s31
@ ------------------------------------------------------------------------------
extract_frustum:
  mov           r12, lr
  add           r2, r1, #96

  vldr.f32      s16, [r0, #12]
  vldr.f32      s17, [r0, #28]
  vldr.f32      s18, [r0, #44]
  vldr.f32      s19, [r0, #60]

  bl            load_near
  vstmia.f32    r2!, {s0 - s3}
  bl            load_left
  vstmia.f32    r2!, {s8 - s11}
  bl            load_bottom
  vstmia.f32    r2!, {s4 - s7}

  bl            insersect_planes
  vstmia.f32    r1!, {s12 - s14}    @ near-left-bottom
  bl            load_top
  bl            insersect_planes
  vstmia.f32    r1!, {s12 - s14}    @ near-left-top
  bl            load_right
  bl            insersect_planes
  vstmia.f32    r1!, {s12 - s14}    @ near-right-top
  bl            load_bottom
  bl            insersect_planes
  vstmia.f32    r1!, {s12 - s14}    @ near-right-bottom
  bl            load_far
  vstmia.f32    r2!, {s0 - s3}
  bl            insersect_planes
  vstmia.f32    r1!, {s12 - s14}    @ far-right-bottom
  bl            load_left
  bl            insersect_planes
  vstmia.f32    r1!, {s12 - s14}    @ far-left-bottom
  bl            load_top
  vstmia.f32    r2!, {s4 - s7}
  bl            insersect_planes
  vstmia.f32    r1!, {s12 - s14}    @ far-left-top
  bl            load_right
  vstmia.f32    r2!, {s8 - s11}
  bl            insersect_planes
  vstmia.f32    r1!, {s12 - s14}    @ far-right-top

  mov           pc, r12

@ ------------------------------------------------------------------------------
@ Loads near plane into registers
@ ------------------------------------------------------------------------------
load_near:
  vldr.f32      s12, [r0, #8]
  vldr.f32      s13, [r0, #24]
  vldr.f32      s14, [r0, #40]
  vldr.f32      s15, [r0, #56]
  vadd.f32      s0, s16, s12
  vadd.f32      s1, s17, s13
  vadd.f32      s2, s18, s14
  vadd.f32      s3, s19, s15
  mov           pc, lr

@ ------------------------------------------------------------------------------
@ Loads far plane into registers
@ ------------------------------------------------------------------------------
load_far:
  vldr.f32      s12, [r0, #8]
  vldr.f32      s13, [r0, #24]
  vldr.f32      s14, [r0, #40]
  vldr.f32      s15, [r0, #56]
  vsub.f32      s0, s16, s12
  vsub.f32      s1, s17, s13
  vsub.f32      s2, s18, s14
  vsub.f32      s3, s19, s15
  mov           pc, lr

@ ------------------------------------------------------------------------------
@ Loads bottom plane into registers
@ ------------------------------------------------------------------------------
load_bottom:
  vldr.f32      s12, [r0, #4]
  vldr.f32      s13, [r0, #20]
  vldr.f32      s14, [r0, #36]
  vldr.f32      s15, [r0, #52]
  vadd.f32      s4, s16, s12
  vadd.f32      s5, s17, s13
  vadd.f32      s6, s18, s14
  vadd.f32      s7, s19, s15
  mov           pc, lr

@ ------------------------------------------------------------------------------
@ Loads top plane into registers
@ ------------------------------------------------------------------------------
load_top:
  vldr.f32      s12, [r0, #4]
  vldr.f32      s13, [r0, #20]
  vldr.f32      s14, [r0, #36]
  vldr.f32      s15, [r0, #52]
  vsub.f32      s4, s16, s12
  vsub.f32      s5, s17, s13
  vsub.f32      s6, s18, s14
  vsub.f32      s7, s19, s15
  mov           pc, lr


@ ------------------------------------------------------------------------------
@ Loads top plane into registers
@ ------------------------------------------------------------------------------
load_left:
  vldr.f32      s12, [r0, #0]
  vldr.f32      s13, [r0, #16]
  vldr.f32      s14, [r0, #32]
  vldr.f32      s15, [r0, #48]
  vadd.f32      s8, s16, s12
  vadd.f32      s9, s17, s13
  vadd.f32      s10, s18, s14
  vadd.f32      s11, s19, s15
  mov           pc, lr

@ ------------------------------------------------------------------------------
@ Loads top plane into registers
@ ------------------------------------------------------------------------------
load_right:
  vldr.f32      s12, [r0, #0]
  vldr.f32      s13, [r0, #16]
  vldr.f32      s14, [r0, #32]
  vldr.f32      s15, [r0, #48]
  vsub.f32      s8, s16, s12
  vsub.f32      s9, s17, s13
  vsub.f32      s10, s18, s14
  vsub.f32      s11, s19, s15
  mov           pc, lr

@ ------------------------------------------------------------------------------
@ Generates a random number using a linear shift register
@ Arguments:
@   none
@ Returns:
@   r0 - random number
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
random:
  stmfd         sp!, {r1 - r2}

  ldr           r1, =1f
  ldr           r0, [r1]

  mov           r2, r0
  eor           r2, r2, r0, lsr #2
  eor           r2, r2, r0, lsr #3
  eor           r2, r2, r0, lsr #5
  and           r2, r2, #1
  lsr           r0, r0, #1
  orr           r0, r0, r2, lsl #15

  str           r0, [r1]

  ldmfd         sp!, {r1 - r2}
  mov           pc, lr
1:
  .long         0xACE1
