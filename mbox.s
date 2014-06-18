@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global mbox_read
.global mbox_write

.include "ports.s"

.section .text
@ ------------------------------------------------------------------------------
@ Reads a value from the mailbox
@
@ Arguments:
@   r0 - Channel
@ Returns:
@   none
@ Clobbers:
@   r1 - Return data
@ ------------------------------------------------------------------------------
mbox_read:
  stmfd     sp!, {r2 - r4}
  ldr       r2, =MBOX_BASE
  eor       r4, r4, r4

1:
  @ Timeout
  add       r4, #1
  tst       r4, #0x80000
  mvnne     r1, #1
  bne       2f

  @ Flush cache
  mcr       p15, #0, r1, c7, c14, #0

  @ Check for ready flag
  ldr       r3, [r2, #0x18]
  tst       r3, #0x40000000
  bne       1b

  @ Read in data (dmb first)
  mcr       p15, #0, r1, c7, c10, #5
  ldr       r3, [r2, #0x00]

  @ Check if the channel is right
  and       r1, r3, #0x0F
  teq       r0, r1
  bne       1b

  @ Extract data
  bic       r1, r3, #0xF
2:
  ldmfd     sp!, {r2 - r4}
  mov       pc, lr


@ ------------------------------------------------------------------------------
@ Writes a value to the mailbox
@
@ Arguments:
@   r0 - channel
@   r1 - data
@ Returns:
@   none
@ Clobbers:
@   none
@ ------------------------------------------------------------------------------
mbox_write:
  stmfd     sp!, {r1 - r4}
  ldr       r2, =MBOX_BASE
  eor       r4, r4

  @ Wait until mailbox is ready
1:
  add       r4, #1
  tst       r4, #0x80000
  bne       2f

  @ Flush cache
  mcr       p15, #0, r3, c7, c14, #0

  ldr       r3, [r2, #0x18]
  tst       r3, #0x80000000
  bne       1b

  @ Send message (dmb first)
  mcr       p15, #0, r3, c7, c10, #5
  orr       r1, r0, r1
  str       r1, [r2, #0x20]

2:
  ldmfd     sp!, {r1 - r4}
  mov       pc, lr
