@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved..global printf
.global printf

.section .text
@ ------------------------------------------------------------------------------
@ Print formatted string.
@ The format string may contain the following sequences:
@   %[n]x - print hexadecimal, pad to n chars
@   %[n]d - print decimal, pad to n chars
@   %s    - print string
@ Arguments are taken from the stack and they must be pushed from the right to
@ the left. Stack cleanup is the responsibility of the caller.
@
@ Arguments:
@   r0    - address of the output format string
@   stack - number(s)/string(s) to be printed, in reversed order
@ Return:
@   None
@ Clobbers:
@   None
@ ------------------------------------------------------------------------------
printf:
  stmfd   sp!, {r0 - r12, lr} @ r0 will store address of the format string
                              @ r1 will store beginning of the output string
  add     r4, sp, #56
  mov     r3, sp

  ldr     lr, =1f
1:
  mov     r2, #0
  ldrb    r1, [r0], #1        @ put next char in r1
  tst     r1, r1
  beq     4f                  @ exit if r2 == '\0'
  cmp     r1, #37
  beq     2f
  strb    r1, [sp, #-1]!      @ store character on stack
  b       1b
2:
  ldrb    r1, [r0], #1
  cmp     r1, #100            @ d = decimal
  beq     printf_d
  cmp     r1, #115            @ s = string
  beq     printf_s
  cmp     r1, #120            @ x = hexadecimal
  beq     printf_x
  cmp     r1, #48
  blo     3f
  cmp     r1, #57
  bhi     3f

  @ Charater is a digit
  subs    r2, r1, #48
  b       2b
3:
  mov     r2, #37
  strb    r2, [sp, #-1]!
  strb    r1, [sp, #-1]!
  tst     r1, r1
  bne     1b
4:
  mov     r1, #0
  strb    r1, [sp, #-1]!      @ Store a null terminator
  @ Reverse buffer
  mov     r4, sp
  sub     r5, r3, #1
5:
  ldrb    r1, [r4]
  ldrb    r2, [r5]
  strb    r1, [r5], #-1
  strb    r2, [r4], #1
  cmp     r4, r5
  blo     5b

  @ Print to stdout with a syscall
  mov     r4, r3
  mov     r0, sp
  ldr     r1, [r3, #4]
  ldr     r2, [r3, #8]
  ldr     r3, [r3, #12]
  bl      gfx_draw_text

  mov     sp, r4
  ldmfd   sp!, {r0 - r12, pc}

@ ------------------------------------------------------------------------------
@ Decimal helper for printf
@ Arguments:
@   r5 - Number to print
@   r2 - Max size of buffer
@ ------------------------------------------------------------------------------
printf_d:
  ldr     r5, [r4], #4
  ldr     r7, =429496730

  sub     r10, sp, #1

  cmp     r5, #0                @ check sign
  bge     1f
  mov     r6, #45               @ r6 = '-'
  neg     r5, r5
1:
  cmp     r2, #0
  bne     3f                    @ if r2 != 0 then write the digits with padding
2:
  @ Handles the case where padding is not required i.e. r2 = 0
  mov     r9, r5
  sub     r5, r5, r5, lsr #30
  umull   r8, r5, r7, r5

  mov     r8, #10
  mul     r8, r5, r8
  sub     r9, r9, r8
  add     r9, #48
  strb    r9, [sp, #-1]!
  cmp     r5, #0
  bgt     2b
  b       5f
3:
  mov     r11, #32              @ r11 = ' '
4:
  @ Handles padding
  mov     r9, r5
  sub     r5, r5, r5, lsr #30
  umull   r8, r5, r7, r5

  mov     r8, #10
  mul     r8, r5, r8
  sub     r9, r9, r8
  add     r9, #48
  strb    r9, [sp, #-1]!
  sub     r2, r2, #1
  cmp     r2, #0
  beq     5f
  cmp     r5, #0
  bgt     4b
5:
  @ Puts minus if negative
  cmp     r6, #45
  bne     6f
  strb    r6, [sp, #-1]!
  sub     r2, r2, #1
6:
  @ Padds with spaces if necessary
  cmp     r2, #0
  ble     7f
  strb    r11, [sp, #-1]!
  sub     r2, r2, #1
  b       6b
7:
  mov     r11, sp
8:
  @ Reverses the buffer
  ldrb    r8, [r10]
  ldrb    r9, [r11]
  strb    r8, [r11], #1
  strb    r9, [r10], #-1
  cmp     r10, r11
  bgt     8b

  mov     pc, lr

@ ------------------------------------------------------------------------------
@ Hexadecimal helper for printf
@ Arguments:
@   r5 - Number to print
@ ------------------------------------------------------------------------------
printf_x:
  ldr     r5, [r4], #4

  tst     r2, r2
  bne     2f

  mov     r6, r5
1:
  add     r2, #1
  lsrs    r6, r6, #4
  bne     1b
2:
  sub     sp, r2

  @ Unroll for first digit
  and     r6, r5, #0xF
  lsr     r5, r5, #4
  cmp     r6, #10
  addlo   r6, #48
  addhs   r6, #55
  strb    r6, [sp]
  mov     r7, #1
  subs    r2, r2, #1
  beq     4f
3:
  @ Write the rest of the digits with padding
  and     r6, r5, #0xF
  cmp     r6, #10
  addlo   r6, #48
  addhs   r6, #55
  lsr     r5, r5, #4
  strb    r6, [sp, r7]
  add     r7, r7, #1
  subs    r2, r2, #1
  bne     3b
4:
  mov     pc, lr

@ ------------------------------------------------------------------------------
@ String helper for printf
@ Arguments:
@   r5 - Address of the string
@ ------------------------------------------------------------------------------
printf_s:
  ldr     r5, [r4], #4
1:
  ldrb    r6, [r5], #1
  cmp     r6, #0
  beq     2f
  strb    r6, [sp, #-1]!
  b       1b
2:
  mov pc, lr
