@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global setup_gfx
.global gfx_fb
.global gfx_swap
.global gfx_clear
.global gfx_draw_trgs
.global gfx_draw_char
.global gfx_draw_text
.global gfx_draw_sprite
.global gfx_draw_image
.global gfx_draw_rect
.global gfx_draw_frame

.include "ports.s"

@ ------------------------------------------------------------------------------
@ Useful macros
@ ------------------------------------------------------------------------------
.macro vswap a, b, c
  vmov.f32    \c, \a
  vmov.f32    \a, \b
  vmov.f32    \b, \c
.endm

.macro swap a, b, c
  mov         \c, \a
  mov         \a, \b
  mov         \b, \c
.endm

.section .data
@ ------------------------------------------------------------------------------
@ Framebuffer structure
@ ------------------------------------------------------------------------------
.align 4
gfx_fb:
  .int 640    @ +0x00: Physical width
  .int 480    @ +0x04: Physical height
  .int 640    @ +0x08: Virtual width
  .int 480    @ +0x0C: Virtual height
  .int 0      @ +0x10: Pitch
  .int 32     @ +0x14: Bit depth
  .int 0      @ +0x18: X
  .int 0      @ +0x1C: Y
  .int 0      @ +0x20: Address
  .int 0      @ +0x24: Size
.align 2

@-------------------------------------------------------------------------------
@ Font bitmap
@ Uses 8x16 bits per character, stored left to right top to bottom
@ 1 - white pixel
@ 0 - black pixel
@-------------------------------------------------------------------------------
.align 4
font:
  .incbin "assets/font.bin"
.align 2

.section .text
@ ------------------------------------------------------------------------------
@ Initialises the framebuffer, retrieving its address
@ ------------------------------------------------------------------------------
setup_gfx:
  stmfd     sp!, {lr}

  @ Request a framebuffer config
  ldr       r0, =0x1
  ldr       r1, =gfx_fb
  orr       r1, #0x40000000
  bl        mbox_write
  bl        mbox_read

  ldmfd     sp!, {pc}

@ ------------------------------------------------------------------------------
@ Clears the screen and depth buffer, setting depth to -1.0f and filling the
@ colour buffer to a given value
@
@ Arguments:
@   r0 - colour
@ Returns:
@   none
@ Clobbers:
@   s0 - s16
@ ------------------------------------------------------------------------------
gfx_clear:
  stmfd     sp!, {r0 - r3}
  ldr       r3, =0x3f800000

  @ Clear registers
  vmov.f32  s0,  r0
  vmov.f32  s1,  r0
  vmov.f32  s2,  r0
  vmov.f32  s3,  r0
  vmov.f32  s4,  r0
  vmov.f32  s5,  r0
  vmov.f32  s6,  r0
  vmov.f32  s7,  r0
  vmov.f32  s8,  r0
  vmov.f32  s9,  r0
  vmov.f32  s10, r0
  vmov.f32  s11, r0
  vmov.f32  s12, r0
  vmov.f32  s13, r0
  vmov.f32  s14, r0
  vmov.f32  s15, r0

  @ Clear 8 pixels at once
  ldr       r0, =gfx_buffer
  ldr       r2, =640 * 480
1:
  vstm.f32  r0!, {s0 - s15}
  subs      r2, r2, #16
  bne       1b

  ldmfd     sp!, {r0 - r3}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Copies color data from back buffer to framebuffer (color data is interleaved
@ with depth data, so it must be extracted). Sets back buffer to the default
@ colour and depth. Every iteration of the loop processes 8 pixels. pld is used
@ to hint the CPU to prefetch data
@ Arguments:
@   none
@ Returns:
@   none
@ Clobbers:
@   s0 - s31
@ ------------------------------------------------------------------------------
gfx_swap:
  stmfd     sp!, {r0 - r12, lr}

  @ Compute addreses
  ldr       r0, =gfx_fb
  ldr       r0, [r0, #0x20]
  ldr       r1, =gfx_buffer

  @ Top half of the screen - blue gradient
  ldr       r12, =0xffffee00
  ldr       r11, =240
1:
  ldr       r2, =640 * 4
  ldr       r4, =0x00020200
  sub       r12, r12, r4
  vmov.f32  s0, r12
  vmov.f32  s1, r12
  vmov.f32  s2, r12
  vmov.f32  s3, r12
  vmov.f32  s4, r12
  vmov.f32  s5, r12
  vmov.f32  s6, r12
  vmov.f32  s7, r12
  vmov.f32  s8, r12
  vmov.f32  s9, r12
  vmov.f32  s10, r12
  vmov.f32  s11, r12
  vmov.f32  s12, r12
  vmov.f32  s13, r12
  vmov.f32  s14, r12
  vmov.f32  s15, r12

  @ Fill 4 lines with one colour
2:
  pld       [r1, #0x100]

  vldm.f32  r1, {s16 - s31}
  vstm.f32  r0!, {s16 - s31}
  vstm.f32  r1!, {s0 - s15}

  subs      r2, r2, #16
  bne       2b

  subs      r11, r11, #4
  bne       1b

  @ Bottom half of the screen - green gradient
  ldr       r12, =0xFF8C9C63
  ldr       r11, =240

3:
  ldr       r2, =640 * 4
  vmov.f32  s0, r12
  vmov.f32  s1, r12
  vmov.f32  s2, r12
  vmov.f32  s3, r12
  vmov.f32  s4, r12
  vmov.f32  s5, r12
  vmov.f32  s6, r12
  vmov.f32  s7, r12
  vmov.f32  s8, r12
  vmov.f32  s9, r12
  vmov.f32  s10, r12
  vmov.f32  s11, r12
  vmov.f32  s12, r12
  vmov.f32  s13, r12
  vmov.f32  s14, r12
  vmov.f32  s15, r12

  ldr       r4, =0x00010101
  sub       r12, r12, r4

  @ Fill 4 lines
4:
  pld       [r1, #0x100]

  vldm.f32  r1, {s16 - s31}
  vstm.f32  r0!, {s16 - s31}
  vstm.f32  r1!, {s0 - s15}

  subs      r2, r2, #16
  bne       4b

  subs      r11, r11, #4
  bne       3b

  @ Draw mountains
  ldr          r0, =mountains
  mov          r1, #0
  mov          r2, #110
  bl           gfx_draw_image

  ldmfd     sp!, {r0 - r12, pc}

@-------------------------------------------------------------------------------
@ Renders a character to the screen
@ Arguments:
@   r0 - Character
@   r1 - x coordinate
@   r2 - y coordinate
@   r3 - RGBA
@ Returns:
@   none
@ Clobbers:
@   r0 - r12
@-------------------------------------------------------------------------------
gfx_draw_char:
  cmp       r0, #127              @ guard against invalid character inputs
  movgt     pc, lr
  stmfd     sp!, {r0 - r10}

  @ calculate start address of the character
  ldr       r9, =font
  add       r9, r9, r0, lsl #4    @ r3 = font + ASCII value * 16

  @ Store address of the buffer & size of the pitch
  ldr       r6, =gfx_buffer
  ldr       r7, =gfx_fb
  ldr       r7, [r7, #0x10]       @ r7 = pitch

  @ loop through the rows
1:
  ldrb      r4, [r9]              @ load byte
  @ loop through the columns
  mov       r5, #0
2:
  tst       r4, #1
  beq       3f

  @ draw pixel at (x + r5, y)
  add       r10, r1, r5
  mla       r8, r7, r2, r6        @ r8 = gfx_buffer + y * pitch
  add       r8, r8, r10, lsl #2   @ r8 = gfx_buffer + y * pitch + (x + r5) * 8

  str       r3, [r8]
3:
  add       r5, #1
  lsr       r4, #1
  cmp       r5, #8
  blt       2b

  add       r2, #1                @ y = y + 1
  add       r9, #1                @ process next byte
  tst       r9, #15               @ check if address of the next char reached
  bne       1b

  ldmfd     sp!, {r0 - r10}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Renders text on screen
@ Arguments:
@   r0 - Address of null terminated string
@   r1 - X position
@   r2 - Y position
@   r3 - RGBA
@ Returns:
@   none
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
gfx_draw_text:
  stmfd     sp!, {r0 - r5, lr}
  mov       r4, r0
  mov       r5, r1                @ save intial x coordinate

1:
  ldrb      r0, [r4]              @ load next character
  add       r4, #1
  cmp       r0, #0                @ check if '\0' reached
  beq       2f

  cmp       r0, #9                @ check if '\t'
  addeq     r1, #64               @ move 8 characters horizontally
  beq       1b

  cmp       r0, #10               @ check if '\n'
  moveq     r1, r5
  addeq     r2, #16               @ go to the new line
  beq       1b

  bl        gfx_draw_char
  add       r1, #8
  b         1b
2:
  ldmfd     sp!, {r0 - r5, pc}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Renders a textured sprite on screen
@ Arguments:
@   r0 - address of the texture
@   r1 - Projection * view matrix
@   r2 - View matrix
@   s0 - width of the quad
@   s1 - height of the quad
@ Returns:
@   none
@ Clobbers:
@   s0 - s31
@ ------------------------------------------------------------------------------
gfx_draw_sprite:
  stmfd       sp!, {r0 - r12, lr}

  @ Get right vector
  vldr.f32    s25, [r2]
  vldr.f32    s26, [r2, #0x10]
  vldr.f32    s27, [r2, #0x20]
  vmul.f32    s25, s25, s0
  vmul.f32    s26, s26, s0
  vmul.f32    s27, s27, s0

  @ Get up vector
  vldr.f32    s28, [r2, #0x04]
  vldr.f32    s29, [r2, #0x14]
  vldr.f32    s30, [r2, #0x24]
  vmla.f32    s25, s28, s1
  vmla.f32    s26, s29, s1
  vmla.f32    s27, s30, s1

  vldm.f32    r1, {s0 - s16}

  @ Top left
  ldr         r3, =0x3f800000
  vmov.f32    s31, r3
  vmov.f32    s16, s25
  vmov.f32    s17, s26
  vmov.f32    s18, s27
  vmov.f32    s19, s31
  bl          mat4_fmul_vec4
  bl          transform_vertex

  @ Bottom right
  vneg.f32    s16, s25
  vneg.f32    s17, s26
  vneg.f32    s18, s27
  vmov.f32    s19, s31
  vmov.f32    s28, s20
  vmov.f32    s26, s21
  vmov.f32    s30, s22
  bl          mat4_fmul_vec4
  bl          transform_vertex
  vmov.f32    s29, s20
  vmov.f32    s25, s21

  @ Check depth range
  ldr         r5, =0xbf800000
  vmov.f32    s21, r5
  vcmp.f32    s30, s21
  fmstat
  ldmltfd     sp!, {r0 -r12, pc}

  vneg.f32    s21, s21
  vcmp.f32    s30, s21
  fmstat
  ldmgtfd     sp!, {r0 -r12, pc}

  mov         r7, #0
  vmov.f32    s2, r7                  @ pixelY
  vmov.f32    s3, r7                  @ pixelX

  ldr         r5, =479
  ftosizs     s24, s26
  vmov.f32    r1, s24
  cmp         r1, #0
  movlt       r1, #0
  vneglt.f32  s2, s26
  cmp         r1, r5
  movgt       r1, r5                  @ y0

  ftosizs     s24, s25
  vmov.f32    r2, s24
  cmp         r2, #0
  movlt       r2, #0
  cmp         r2, r5
  movgt       r2, r5                  @ y1

  ldr         r5, =639
  ftosizs     s24, s29
  vmov.f32    r3, s24
  cmp         r3, #0
  movlt       r3, #0
  vneglt.f32  s3, s29
  cmp         r3, r5
  movgt       r3, r5                  @ x0

  ftosizs     s24, s28
  vmov.f32    r4, s24
  cmp         r4, #0
  movlt       r4, #0
  cmp         r4, r5
  movgt       r4, r5                  @ x1

  ldr         r5, =gfx_fb
  ldr         r5, [r5, #0x10]         @ r5 = pitch

  ldr         r6, =gfx_buffer
  mla         r6, r5, r1, r6
  add         r6, r6, r3, lsl #2

  @ Check bounds
  subs        r2, r2, r1
  ble         3f
  cmp         r4, r3
  ble         3f

  ldr         r8, [r0], #4
  vmov.f32    s0, r8
  fsitos      s0, s0
  vsub.f32    s6, s25, s26            @ height
  vdiv.f32    s0, s0, s6

  ldr         r9, [r0], #4
  vmov.f32    s1, r9
  fsitos      s1, s1
  vsub.f32    s6, s28, s29            @ width
  vdiv.f32    s1, s1, s6
  lsl         r9, r9, #2

  ldr         r7, =0x3f800000         @ 1.0f
  vmov.f32    s4, r7

  @ Loop over scanline
1:
  mov         r12, r6
  subs        r7, r4, r3

  vmul.f32    s6, s2, s0
  ftosizs     s6, s6
  vmov.f32    r1, s6
  vmov.f32    s7, s3
  mla         r8, r1, r9, r0
2:
  vmul.f32    s6, s7, s1
  ftosizs     s6, s6
  vmov.f32    r1, s6

  @ Texture lookup
  ldr         r11, [r8, r1, lsl #2]
  lsrs        r1, r11, #24
  strne       r11, [r6]
  add         r6, #4
  vadd.f32    s7, s7, s4
  subs        r7, r7, #1
  bgt         2b

  add         r6, r12, r5
  vadd.f32    s2, s2, s4
  subs        r2, r2, #1
  bgt         1b
3:
  ldmfd       sp!, {r0 -r12, pc}

@ ------------------------------------------------------------------------------
@ Draws an image on screen
@ Arguments:
@   r0 - image
@   r1 - x on screen
@   r2 - y on screen
@ ------------------------------------------------------------------------------
gfx_draw_image:
  cmp         r1, #640
  movge       pc, lr
  cmp         r2, #480
  movge       pc, lr

  stmfd       sp!, {r0 - r12, lr}

  ldr         r4, [r0], #4           @ Width
  ldr         r3, [r0], #4           @ Height

  cmn         r0, r3
  stmmifd     sp!, {r0 - r12, pc}
  cmn         r1, r4
  stmmifd     sp!, {r0 - r12, pc}

  ldr         r10, =gfx_fb
  ldr         r10, [r10, #0x10]       @ r10 = pitch
  lsl         r12, r3, #2             @ image pitch
  ldr         r11, =gfx_buffer        @ buffer

  tst         r1, r1
  addmi       r3, r3, r1
  submi       r0, r0, r1, lsl #2      @ Clamp left
  movmi       r1, #0

  tst         r2, r2
  addmi       r4, r4, r2
  negmi       r2, r2
  mlami       r0, r12, r2, r0
  movmi       r2, #0                  @ Clamp top

  add         r6, r1, r3
  cmp         r6, #640
  subge       r6, #640
  subge       r3, r3, r6

  add         r6, r2, r4
  cmp         r6, #480
  subge       r6, #480
  subge       r4, r4, r6

  mla         r11, r2, r10, r11
  add         r11, r11, r1, lsl #2

  tst         r1, r1
  addmi       r3, r3, r1
  negmi       r1, r1
1:
  mov         r7, r0
  mov         r8, r11
  mov         r6, r3
2:
  ldr         r9, [r0], #4
  tst         r9, #0xFF000000
  strne       r9, [r11], #4
  addeq       r11, r11, #4

  subs        r6, r6, #1
  bne         2b

  add         r0, r7, r12
  add         r11, r8, r10
  subs        r4, r4, #1
  bne         1b

  ldmfd       sp!, {r0 - r12, pc}

@ ------------------------------------------------------------------------------
@ Draws a line using Bresenham's algorithm
@   r0 - x0
@   r1 - y0
@   r2 - x1
@   r3 - y1
@   r4 - colour
@ Returns:
@   none
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
gfx_draw_line:
  stmfd       sp!, {r0 - r12, lr}

  subs        r5, r2, r0
  neglt       r5, r5                  @ r5 = dx = abs(x1 - x0)
  subs        r6, r3, r1
  neggt       r6, r6                  @ r6 = -dy = -abs(y1 - y0)

  cmp         r0, r2
  movle       r7, #1
  movgt       r7, #-1                 @ r7 = x0 < x1 ? 1 : -1
  cmp         r1, r3
  movle       r8, #1
  movgt       r8, #-1                 @ r8 = y0 < y1 ? 1 : -1

  adds        r9, r5, r6              @ err = dx - dy

  ldr         r10, =gfx_fb
  ldr         r10, [r10, #0x10]       @ r10 = pitch

  ldr         r11, =gfx_buffer
1:
  cmp         r0, #0
  blt         2f
  cmp         r1, #0
  blt         2f

  ldr         r12, =639
  cmp         r0, r12
  bge         2f
  ldr         r12, =479
  cmp         r1, r12
  bge         2f

  mla         r12, r10, r1, r11
  add         r12, r12, r0, lsl #3    @ emit (x0, y0)
  str         r4, [r12]
2:
  teq         r0, r2
  teqeq       r1, r3                  @ bail if x0 == x1 && y0 == y1
  beq         3f

  lsl         r12, r9, #1
  cmp         r12, r6
  addgt       r9, r9, r6
  addgt       r0, r0, r7

  cmp         r12, r5
  addlt       r9, r9, r5
  addlt       r1, r1, r8

  b           1b
3:
  ldmfd       sp!, {r0 - r12, pc}

@ ------------------------------------------------------------------------------
@ Renders a list of triangles
@ Arguments:
@   r0 - Vertex data
@   r1 - Index data
@   r2 - Number of triangles
@   r3 - MVP matrix
@   r4 - Light direction
@ Returns:
@   none
@ Clobbers:
@   s0 - s31
@ ------------------------------------------------------------------------------
gfx_draw_trgs:
  stmfd       sp!, {r0 - r12, lr}

1:
  subs        r2, r2, #1
  blt         3f

  ldm         r1!, {r10, r11, r12}  @ Indices
  vldm.f32    r3, {s0 - s15}        @ MVP matrix
  eor         r5, r5, r5            @ Number of visible vertices
  add         r1, #12

  add         r10, r0, r10, lsl #4
  vldm.f32    r10, {s16 - s19}      @ r10 = &v0.xyz
  bl          mat4_fmul_vec4
  bl          transform_vertex
  vmov.f32    s30, s22
  vmov.f32    s29, s21
  vmov.f32    s28, s20              @ v0

  add         r11, r0, r11, lsl #4
  vldm.f32    r11, {s16 - s19}      @ r11 = &v1.xyz
  bl          mat4_fmul_vec4
  bl          transform_vertex
  vmov.f32    s27, s22
  vmov.f32    s26, s21
  vmov.f32    s25, s20              @ v1

  add         r12, r0, r12, lsl #4
  vldm.f32    r12, {s16 - s19}      @ r12 = &v2.xyz
  bl          mat4_fmul_vec4
  bl          transform_vertex
  vmov.f32    s24, s22
  vmov.f32    s23, s21
  vmov.f32    s22, s20              @ v2

  @ If at least one vertex is not clipped, continue
  tst         r5, r5
  bne         2f

  @ Check whether triangle intersects the viewport
  vcmp.f32    s22, #0
  fmstat
  vcmplt.f32  s25, #0
  fmstat
  vcmplt.f32  s28, #0
  fmstat
  blt         1b

  vcmp.f32    s23, #0
  fmstat
  vcmplt.f32  s26, #0
  fmstat
  vcmplt.f32  s29, #0
  fmstat
  blt         1b

  ldr         r5, =0xbf800000
  vmov.f32    s21, r5
  vcmp.f32    s24, s21
  fmstat
  vcmplt.f32  s27, s21
  fmstat
  vcmplt.f32  s30, s21
  fmstat
  blt         1b

  vneg.f32    s21, s21
  vcmp.f32    s24, s21
  fmstat
  vcmpgt.f32  s27, s21
  fmstat
  vcmpgt.f32  s30, s21
  fmstat
  bgt         1b

  ldr         r5, =0x43ef8000
  vmov.f32    s21, r5
  vcmp.f32    s23, s21
  fmstat
  vcmpgt.f32  s26, s21
  fmstat
  vcmpgt.f32  s29, s21
  fmstat
  bgt         1b

  ldr         r5, =0x441fc000
  vmov.f32    s21, r5
  vcmp.f32    s22, s21
  fmstat
  vcmpgt.f32  s25, s21
  fmstat
  vcmpgt.f32  s28, s21
  fmstat
  bgt         1b

  @ Cull back faces
2:
  vmul.f32    s0, s28, s26          @ Check if vertices are in ccw order
  vmla.f32    s0, s22, s29          @ (note: y coordinates are flipped)
  vmla.f32    s0, s25, s23          @ | x0 y0 1 |
  vmls.f32    s0, s22, s26          @ | x1 y1 1 | < 0
  vmls.f32    s0, s28, s23          @ | x2 y2 1 |
  vmls.f32    s0, s25, s29
  vmov.f32    r5, s0
  tst         r5, r5

  beq         1b
  bpl         1b

  bl          shade_triangle
  bl          draw_triangle
  b           1b
3:

  ldmfd       sp!, {r0 - r12, pc}

@ ------------------------------------------------------------------------------
@ Computes window coordinates from normalised device coordinates by performing
@ perspective division. Also checks if the vertex is visble on the screen.
@ If the vertex is not clipped, r5 is incremented.
@ Arguments:
@   s16 - s19: Vector
@ Returns:
@   s20 - s23: (x, y, z, w)
@ Clobbers:
@   s20 - s24, r5, r6
@ ------------------------------------------------------------------------------
transform_vertex:
  vcmp.f32    s23, #0
  fmstat
  ble         1f                @ w <= 0.0f

  vcmp.f32    s20, s23
  fmstat
  vcmple.f32  s21, s23
  fmstat
  vcmple.f32  s22, s23
  fmstat
  vneg.f32    s23, s23
  bgt         1f                @ x > w || y > w || z > w

  vcmp.f32    s23, s20
  fmstat
  vcmple.f32  s23, s21
  fmstat
  vcmple.f32  s23, s22
  fmstat
  addle       r5, #1            @ -w <= x || -w <= y || -w <= z
1:
  ldr         r6, =0x3f800000
  vmov.f32    s31, r6           @ 1.0f

  vdiv.f32    s20, s20, s23     @ x = (1.0f - x) * 320
  vsub.f32    s20, s31, s20
  ldr         r6, =0x43a00000
  vmov.f32    s24, r6           @ s24 = 320.0f
  vmul.f32    s20, s20, s24

  vdiv.f32    s21, s21, s23     @ y = (1.0f + y) * 240
  vadd.f32    s21, s31, s21
  ldr         r6, =0x43700000
  vmov.f32    s24, r6           @ s24 = 320.0f
  vmul.f32    s21, s21, s24

  vdiv.f32    s22, s22, s23     @ w = -w
  vneg.f32    s22, s22

  mov         pc, lr

@ ------------------------------------------------------------------------------
@ Performs per-polygon shading, computing a colour value for the entire
@ triangle
@ Arguments:
@   r10, r11, r12 - triangle indices
@ Returns:
@   r12 - colour value
@ Clobbers:
@   s0 - s15
@ ------------------------------------------------------------------------------
shade_triangle:
  vldm.f32      r10, {s0 - s2}      @ r10 = &v0.rgb
  vldm.f32      r11, {s3 - s5}      @ r11 = &v1.rgb
  vldm.f32      r12, {s6 - s8}      @ r12 = &v2.rgb

  @ Compute the normal vector
  vsub.f32      s0, s0, s3
  vsub.f32      s1, s1, s4
  vsub.f32      s2, s2, s5
  vsub.f32      s6, s6, s3
  vsub.f32      s7, s7, s4
  vsub.f32      s8, s8, s5

  vmul.f32      s3, s1, s8
  vmls.f32      s3, s7, s2
  vmul.f32      s4, s6, s2
  vmls.f32      s4, s0, s8
  vmul.f32      s5, s0, s7
  vmls.f32      s5, s1, s6

  @ Normalize it
  vmul.f32      s0, s3, s3
  vmla.f32      s0, s4, s4
  vmla.f32      s0, s5, s5
  vsqrt.f32     s0, s0

  vdiv.f32      s3, s3, s0
  vdiv.f32      s4, s4, s0
  vdiv.f32      s5, s5, s0

  @ Compute the dot product between the normal
  @ and the light direction
  vldm.f32      r4, {s0 - s2}
  vmul.f32      s0, s0, s3
  vmla.f32      s0, s1, s4
  vmla.f32      s0, s2, s5

  @ Compute light intensity: ambient + diffuse
  ldr           r5, =0x3e4ccccd
  ldr           r6, =0x3f800000
  vmov.f32      s1, r5
  vmov.f32      s2, r6

  vcmp.f32      s0, #0
  fmstat
  vmovlt.f32    s0, s1
  vaddgt.f32    s0, s1

  ldr           r5, =0x437f0000
  vmov.f32      s1, r5
  vmul.f32      s0, s1

  sub           r1, #12
  vldm.f32      r1, {s3 - s5}
  add           r1, #12
  vmul.f32      s3, s3, s0
  vmul.f32      s4, s4, s0
  vmul.f32      s5, s5, s0

  ldr           r12, =0xff000000

  ftosizs       s3, s3
  vmov.f32      r11, s3
  cmp           r11, #0
  movlt         r11, #0
  andgt         r11, r11, #0xFF
  orr           r12, r12, r11, lsl #0

  ftosizs       s4, s4
  vmov.f32      r11, s4
  cmp           r11, #0
  movlt         r11, #0
  andgt         r11, r11, #0xFF
  orr           r12, r12, r11, lsl #8

  ftosizs       s5, s5
  vmov.f32      r11, s5
  cmp           r11, #0
  movlt         r11, #0
  andgt         r11, r11, #0xFF
  orr           r12, r12, r11, lsl #16

  mov           pc, lr

@ ------------------------------------------------------------------------------
@ Rasterises a triangle with colour interpolation
@ Arguments:
@   r10: v0 data
@   s28 - s30: v0(x, y, z)
@   r11: v1 data
@   s25 - s27: v1(x, y, z)
@   r12: v2 data
@   s22 - s24: v2(x, y, z)
@ Returns:
@   none
@ Clobers:
@   s0 - s31, r0 - r12
@ ------------------------------------------------------------------------------
draw_triangle:
  stmfd         sp!, {r0 - r4, lr}

  @ Sort the points: v0.y < v1.y < v2.y
  vcmp.f32      s29, s26
  fmstat
  ble           1f
  vswap         s28, s25, s16
  vswap         s29, s26, s16
  vswap         s30, s27, s16
1:
  vcmp.f32      s29, s23
  fmstat
  ble           1f
  vswap         s28, s22, s16
  vswap         s29, s23, s16
  vswap         s30, s24, s16
1:
  vcmp.f32      s26, s23
  fmstat
  ble           1f
  vswap         s25, s22, s16
  vswap         s26, s23, s16
  vswap         s27, s24, s16
1:

  @ Convert y coordinates to integers and clamp them to range [0, 480)
  ldr           r3, =479

  ftosizs       s0, s29
  vmov.s32      r0, s0
  cmp           r0, #0
  movlt         r0, #0
  cmp           r0, r3
  movgt         r0, r3              @ r0 = clamp(v0.y, 0, 479)
  ftosizs       s0, s26
  vmov.s32      r1, s0
  cmp           r1, #0
  movlt         r1, #0
  cmp           r1, r3
  movgt         r1, r3              @ r1 = clamp(v1.y, 0, 479)
  ftosizs       s0, s23
  vmov.s32      r2, s0
  cmp           r2, #0
  movlt         r2, #0
  cmp           r2, r3
  movgt         r2, r3              @ r2 = clamp(v2.y, 0, 479)

  @ Compute bounds on x axis
  vcmp.f32      s25, s22
  fmstat
  vmovgt.f32    s1, s25
  vmovgt.f32    s0, s22
  vmovle.f32    s1, s22
  vmovle.f32    s0, s25
  vcmp.f32      s28, s0
  fmstat
  vmovle.f32    s0, s28             @ s0 = min(v0.x, v1.x, v2.x)
  vcmp.f32      s28, s1
  fmstat
  vmovgt.f32    s1, s28             @ s1 = max(v0.x, v1.x, v2.x)

  ldr           r3, =0
  vmov.f32      s21, r3
  vcmp.f32      s0, s21
  fmstat
  vmovlt.f32    s0, s21
  vcmp.f32      s1, s21
  fmstat
  vmovlt.f32    s1, s21

  ldr           r3, =0x441fc000     @ r3 = 639.0f
  vmov.f32      s21, r3
  vcmp.f32      s0, s21
  fmstat
  vmovgt.f32    s0, s21             @ s0 = clamp(s0, 0, 639)
  vcmp.f32      s1, s21
  fmstat
  vmovgt.f32    s1, s21             @ s1 = clamp(s1, 0, 639)

  @ Compute scanline length
  ldr           r3, =gfx_fb
  ldr           r3, [r3, #0x10]     @ r3 = pitch

@ ------------------------------------------------------------------------------
@ Rasterizes the top triangle
@ ------------------------------------------------------------------------------
raster_top:
  stmfd         sp!, {r0, r1, r2}
  vstmdb.f32    sp!, {s22 - s30}

  @ Gradient for v2 - v0
  vsub.f32      s31, s23, s29
  vsub.f32      s2, s22, s28
  vdiv.f32      s2, s2, s31       @ gradLeftX

  @ Gradient for v1 - v0
  vsub.f32      s22, s26, s29
  vsub.f32      s7, s25, s28
  vdiv.f32      s7, s7, s22       @ gradRightX

  @ If gradient of v1 - v0 is larger than the gradient
  @ of v2 - v0, the gradients must be swapped
  vcmp.f32      s7, s2
  fmstat
  blt           1f
  vswap         s7, s2, s4
  vswap         s3, s8, s4
  vswap         s31, s22, s4
1:

  @ Loop through all scanlines and fill triangles line by line
  ldr           r5, =0x3f800000
  vmov.f32      s22, r5

  ftosis        s31, s29
  vmov.f32      r5, s31
  cmp           r5, #0
  neglt         r5, r5
  movgt         r5, #0

  subs          r1, r1, r0
  ble           1f

  ldr           r4, =gfx_buffer
  mla           r4, r0, r3, r4    @ r4 = first row
2:
  vmov.f32      s31, r5
  fsitos        s31, s31

  bl            draw_span

  add           r4, r3
  add           r5, #1
  subs          r1, #1
  bge           2b
1:
  vldmia.f32    sp!, {s22 - s30}
  ldmfd         sp!, {r0, r1, r2}

@ ------------------------------------------------------------------------------
@ Rasterizes the bottom triangle
@ ------------------------------------------------------------------------------
raster_bottom:
  @ Gradient for v0 - v2
  vsub.f32      s2, s28, s22
  vsub.f32      s31, s23, s29
  vsub.f32      s3, s30, s24
  vdiv.f32      s2, s2, s31       @ gradLeftX

  @ Gradient for v1 - v2
  vsub.f32      s7, s25, s22
  vsub.f32      s29, s23, s26
  vsub.f32      s8, s27, s24
  vdiv.f32      s7, s7, s29       @ gradRightX

  @ If gradient of v1 - v0 is larger than the gradient
  @ of v2 - v0, the gradients must be swapped
  vcmp.f32      s7, s2
  fmstat
  blt           1f
  vswap         s2, s7, s4
  vswap         s3, s8, s4
  vswap         s4, s9, s4
  vswap         s29, s31, s4
1:

  @ Setup origins
  vmov.f32      s28, s22
  vmov.f32      s30, s24

  @ Loop through all scanlines and fill triangles line by line
  ldr           r4, =gfx_buffer
  mla           r4, r2, r3, r4    @ r4 = first row

  subs          r2, r1
  ble           1f

  ftosis        s24, s23
  vmov.f32      r6, s24
  ldr           r7, =479
  cmp           r6, r7
  subge         r5, r6, r7
  movlt         r5, #0

2:
  vmov.f32      s31, r5
  fsitos        s31, s31

  bl            draw_span

  sub           r4, r3
  add           r5, #1
  subs          r2, #1
  bge           2b
1:
  ldmfd         sp!, {r0 - r4, pc}

@ ------------------------------------------------------------------------------
@ Draws a span between two points on a scanline, interpolating colour and
@ depth values and writing data into the back buffer. Note that instructions
@ are arranged in order to make full use of the CPUs ability to place up to
@ 8 instructions in the pipeline
@
@ Arguments:
@   r4 - address of scanline
@   s0 - min X
@   s1 - max X
@   s2 - s6   - right edge gradient (x, d, r, g, b)
@   s7 - s11  - left edge gradient (x, d, r, g, b)
@ Returns:
@   none
@ Clobbers:
@   r6 - r12, s12 - s27
@ ------------------------------------------------------------------------------
draw_span:
  mov           r8, #0
  vmov.f32      s12, s28
  vmla.f32      s12, s7, s31          @ x0
  ftosizs       s12, s12
  fsitos        s12, s12
  vmov.f32      s16, s28
  vmla.f32      s16, s2, s31          @ x1

  vsub.f32      s20, s16, s12         @ length of span

  vcmp.f32      s0, s12
  fmstat
  vsubgt.f32    s26, s0, s12
  ftosizsgt     s26, s26
  vmovgt.f32    r8, s26               @ x0'
  vmovgt.f32    s12, s0
  vcmp.f32      s1, s12
  fmstat
  vmovlt.f32    s12, s1               @ clamp(x0, s0, s1)
  vcmp.f32      s1, s16
  fmstat
  vmovlt.f32    s16, s1
  vcmp.f32      s0, s16
  fmstat
  vmovgt.f32    s16, s0               @ clamp(x1, s0, s1)

  ftosis        s12, s12
  vmov.f32      r6, s12               @ x0
  ftosis        s16, s16
  vmov.f32      r7, s16               @ x1
  subs          r7, r6
  movle         pc, lr                @ x0 < x1

  add           r6, r4, r6, lsl #2    @ r6 - first pixel in scanline
  ldr           r10, =0x437f0000
  vmov.f32      s22, r10              @ 255.0f
1:
  vmov.f32      s26, r8
  fsitos        s26, s26

  @ Interpolate colour
  str           r12, [r6], #4
  add           r8, #1
  subs          r7, #1
  bge           1b

  mov           pc, lr

@-------------------------------------------------------------------------------
@ Renders a rectangle of size r2xr3 and colour r4 starting at (r0, r1)
@ Arguments:
@   r0 - x coordinate
@   r1 - y coordinate
@   r2 - width
@   r3 - height
@   r4 - colour
@ Returns:
@   none
@ Clobbers:
@   none
@-------------------------------------------------------------------------------
gfx_draw_rect:
  cmp       r2, #0
  moveq     pc, lr

  stmfd     sp!, {r0 - r10}

  ldr       r6, =gfx_buffer
  ldr       r7, =gfx_fb
  ldr       r7, [r7, #0x10]       @ r7 = pitch

  add       r10, r1, r3           @ r10 = y + height
1:
  mov       r5, #0
2:
  add       r9, r0, r5            @ r9 = x + r5
  mla       r8, r7, r1, r6        @ r8 = gfx_buffer + y * pitch
  add       r8, r8, r9, lsl #2    @ r8 = gfx_buffer + y * pitch + (x + r5) * 4

  str       r4, [r8]

  add       r5, #1
  cmp       r5, r2
  ble       2b

  add       r1, #1
  cmp       r1, r10
  ble       1b
3:
  ldmfd     sp!, {r0 - r10}
  mov       pc, lr

@-------------------------------------------------------------------------------
@ Renders a 2px frame of size r2xr3 and colour r4 starting at (r0, r1)
@ Arguments:
@   r0 - x coordinate
@   r1 - y coordinate
@   r2 - width
@   r3 - height
@   r4 - colour
@ Returns:
@   none
@ Clobbers:
@   none
@-------------------------------------------------------------------------------
gfx_draw_frame:
  cmp       r2, #0
  moveq     pc, lr

  stmfd     sp!, {r0 - r12}

  ldr       r6, =gfx_buffer
  ldr       r7, =gfx_fb
  ldr       r7, [r7, #0x10]

  @ Draw horizontal lines
  add       r10, r1, #1
  add       r11, r1, r3
  sub       r12, r11, #1
  mov       r5, #0

1:
  add       r9, r0, r5

  mla       r8, r7, r1, r6
  add       r8, r8, r9, lsl #2
  str       r4, [r8]

  mla       r8, r7, r10, r6
  add       r8, r8, r9, lsl #2
  str       r4, [r8]

  mla       r8, r7, r11, r6
  add       r8, r8, r9, lsl #2
  str       r4, [r8]

  mla       r8, r7, r12, r6
  add       r8, r8, r9, lsl #2
  str       r4, [r8]

  add       r5, #1
  cmp       r5, r2
  ble       1b

  @ Draw vertical lines
  add       r10, r0, #1
  add       r11, r0, r2
  sub       r5, r11, #1
  add       r1, r1, #2

2:
  mla       r2, r7, r1, r6

  add       r8, r2, r0, lsl #2
  str       r4, [r8]      

  add       r8, r2, r10, lsl #2
  str       r4, [r8]

  add       r8, r2, r11, lsl #2
  str       r4, [r8]

  add       r8, r2, r5, lsl #2
  str       r4, [r8]

  add       r1, #1
  cmp       r1, r12
  blt       2b

  ldmfd     sp!, {r0 - r12}
  mov       pc, lr
