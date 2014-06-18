@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global start

.include "ports.s"

.section .text
@ ------------------------------------------------------------------------------
@ Entry point of the application
@ ------------------------------------------------------------------------------
kernel:
  bl        setup_stack
  bl        setup_ivt
  bl        setup_vfp
  bl        setup_gfx
  bl        setup_cache
  bl        setup_input
  bl        setup_sound
  b         setup_game

@ ------------------------------------------------------------------------------
@ Sets up stacks for all operating modes
@ ------------------------------------------------------------------------------
setup_stack:
  mov       r0, #0xD1       @ FIQ
  msr       cpsr, r0
  ldr       sp, =stack_fiq
  mov       r0, #0xD2       @ IRQ
  msr       cpsr, r0
  ldr       sp, =stack_irq
  mov       r0, #0xD7       @ ABT
  msr       cpsr, r0
  ldr       sp, =stack_abt
  mov       r0, #0xDB       @ UND
  msr       cpsr, r0
  ldr       sp, =stack_und
  mov       r0, #0xDF       @ SYS
  msr       cpsr, r0
  ldr       sp, =stack_sys
  mov       r0, #0xD3       @ SVC
  msr       cpsr, r0
  ldr       sp, =stack_svc
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Relocates the interrupt vector table
@ ------------------------------------------------------------------------------
setup_ivt:
  ldr       r10, =ivt_start
  ldr       r11, =0x00000000
  ldm       r10!, {r0 - r7}
  stm       r11!, {r0 - r7}
  ldm       r10,  {r0 - r7}
  stm       r11,  {r0 - r7}
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Enables the L1 cache
@ ------------------------------------------------------------------------------
setup_cache:
  mov       r0, #0
  mcr       p15, 0, r0, c7, c7, 0     @ Invalidate caches
  mcr       p15, 0, r0, c8, c7, 0     @ Invalidate TLB
  mrc       p15, 0, r0, c1, c0, 0
  ldr       r1, =0x1004
  orr       r0, r0, r1                @ Set L1 enable bit
  mcr       p15, 0, r0, c1, c0, 0
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Enables the vectored floating point unit
@ ------------------------------------------------------------------------------
setup_vfp:
  mrc       p15, #0, r0, c1, c0, #2
  orr       r0, r0, #0xF00000         @ Single + double precision
  mcr       p15, #0, r0, c1, c0, #2
  mov       r0, #0x40000000           @ Set VFP enable bit
  fmxr      fpexc, r0
  mov       pc, lr

@ ------------------------------------------------------------------------------
@ Interrupt vector table
@
@ On startup, this table has to be relocated to the start of memory.
@ It contains jump to interrupt handlers.
@ ------------------------------------------------------------------------------
ivt_start:
.rept 8
  ldr pc, [pc, #0x18]
.endr
.word handler_hang
.word handler_undef
.word handler_hang
.word handler_hang
.word handler_hang
.word .
.word handler_hang
.word handler_hang

@ ------------------------------------------------------------------------------
@ Hang when something bad happens
@ ------------------------------------------------------------------------------
handler_hang:
  b         .

@ ------------------------------------------------------------------------------
@ Undefined instructions - clears FP exception bit
@ Like pro windows devs, we put a shitton of effort
@ into making an awesome, blue panic screeen
@ ------------------------------------------------------------------------------
handler_undef:
  @ Reset VFP
  mov         r0, #0x40000000
  fmxr        fpexc, r0

  @ Arguments for printf
  vstm.f32    sp!, {s0 - s31}
  stmfd       sp!, {r0 - r12}
  stmfd       sp!, {lr}

  @ Nice blue background
  ldr         r0, =0xFFFF0000
  bl          gfx_clear

  @ Print address
  ldr         r0, =1f
  mov         r1, #100
  mov         r2, #100
  ldr         r3, =0xFFFFFFFF
  bl          printf
  add         sp, sp, #4

  @ Present error message
  bl          gfx_swap

  @ Hang
  b           .

1:
  .ascii      "VFP crashed:\n"
  .ascii      " PC: %8x\n"
  .ascii      " r0: %8x   r1: %8x   r2: %8x   r3: %8x\n"
  .ascii      " r4: %8x   r5: %8x   r6: %8x   r7: %8x\n"
  .ascii      " r8: %8x   r9: %8x  r10: %8x  r11: %8x\n"
  .ascii      " s0: %8x   s1: %8x   s2: %8x   s3: %8x\n"
  .ascii      " s4: %8x   s5: %8x   s6: %8x   s7: %8x\n"
  .ascii      " s8: %8x   s9: %8x  s10: %8x  s11: %8x\n"
  .ascii      "s12: %8x  s13: %8x  s14: %8x  s15: %8x\n"
  .ascii      "s16: %8x  s17: %8x  s18: %8x  s19: %8x\n"
  .ascii      "s20: %8x  s21: %8x  s22: %8x  s23: %8x\n"
  .ascii      "s24: %8x  s25: %8x  s26: %8x  s27: %8x\n"
  .ascii      "s28: %8x  s29: %8x  s30: %8x  s31: %8x\n"
  .ascii      "\0"
  .align 2
