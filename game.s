@ This file is part of the Team 28 Project
@ Licensing information can be found in the LICENSE file
@ (C) 2014 The Team 28 Authors. All rights reserved.
.global setup_game
.global mtx_proj
.global mtx_model
.global mtx_view
.global mtx_temp
.global mtx_vp
.global mtx_mvp
.global mtx_mp
.global mtx_id
.global player_pos
.global light_dir
.global wrench
.global rocket
.global bullet
.global flare
.global score
.global building_small
.global building_medium
.global building_large
.global mountains
.global tristan
.global monkey

.include "ports.s"

.section .data
@ ------------------------------------------------------------------------------
@ Common assets
@ ------------------------------------------------------------------------------
bullet:          .incbin  "assets/bullet.bin"
rocket:          .incbin  "assets/rocket.bin"
wrench:          .incbin  "assets/wrench.bin"
flare:           .incbin  "assets/flare.bin"
mountains:       .incbin  "assets/mountains.bin"
tristan:         .incbin  "assets/tristan.bin"
monkey:          .incbin  "assets/monkey.bin"
pixfox:          .incbin  "assets/pifox.bin"

@ ------------------------------------------------------------------------------
@ Pad ascii to a fixed width
@ ------------------------------------------------------------------------------
.macro death_msg x, string
8:
  .long \x
  .ascii "\string"
9:
  .iflt 64 - (9b - 8b)
    .error "String too long"
  .endif
  .ifgt 64 - (9b - 8b)
    .zero 64 - (9b - 8b)
  .endif
.endm

@ ------------------------------------------------------------------------------
@ Transformation matrices
@ ------------------------------------------------------------------------------
mtx_proj:        .float 1.810660, 0.0,        0.0,        0.0
                 .float 0.0,      2.4142136,  0.0,        0.0
                 .float 0.0,      0.0,       -1.0040080, -1.0
                 .float 0.0,      0.0,       -2.0040080,  0.0
mtx_model:       .float 1.0,      0.0,        0.0,        0.0
                 .float 0.0,      1.0,        0.0,        0.0
                 .float 0.0,      0.0,        1.0,        0.0
                 .float 0.0,      0.0,        0.0,        1.0
mtx_view:        .float 1.0,      0.0,        0.0,        0.0
                 .float 0.0,      1.0,        0.0,        0.0
                 .float 0.0,      0.0,        1.0,        0.0
                 .float 0.0,      0.0,        0.0,        1.0
mtx_temp:        .space 64, 0
mtx_vp:          .space 64, 0
mtx_mvp:         .space 64, 0
mtx_mp:          .space 64, 0
mtx_id:          .float 1.0, 0.0, 0.0, 0.0
                 .float 0.0, 1.0, 0.0, 0.0
                 .float 0.0, 0.0, 1.0, 0.0
                 .float 0.0, 0.0, 0.0, 1.0

@ ------------------------------------------------------------------------------
@ Light direction
@ ------------------------------------------------------------------------------
light_dir:       .float 0.3, -0.57, -0.57, 0.0

.section .text
@ ------------------------------------------------------------------------------
@ Enables interrupts & starts the game
@ ------------------------------------------------------------------------------
setup_game:
  mov         r0, #0xDF
  msr         cpsr, r0
  b           start_loop

@ ------------------------------------------------------------------------------
@ Start screen displayed on boot
@ ------------------------------------------------------------------------------
start_loop:
  ldr         r0, =0xFF441111
  bl          gfx_clear

  @ Draw pifox title card
  ldr         r0, =pixfox
  mov         r1, #203
  mov         r2, #30
  bl          gfx_draw_image

  bl          draw_sprites
  bl          draw_start
  bl          gfx_swap

  bl          update_sound
  bl          update_input

  @ Loop until start is pressed
  ldr         r0, =button_pressed
  ldr         r0, [r0]
  tst         r0, #0x08
  beq         start_loop
  b           game_loop


@ ------------------------------------------------------------------------------
@ Death screen
@ ------------------------------------------------------------------------------
death_loop:

  @ Clear sounds 
  bl          snd_stop_roll
  bl          snd_stop_bullet
  bl          snd_stop_rock
  bl          snd_stop_crash
  bl          snd_stop_rocket
  bl          snd_stop_cantlet
  bl          snd_stop_pickup

  @ Play fail sound
  bl          snd_play_fail

  @ Record high score
  ldr         r1, =player_score
  ldr         r1, [r1]
  ldr         r0, =player_high_score
  ldr         r0, [r0]
  cmp         r1, r0
  ldrgt       r0, =player_high_score
  strgt       r1, [r0]

  @ Generate random death message index
  bl          random
  and         r1, r0, #0x3
1:
  ldr         r0, =0xFF0044ff
  bl          gfx_clear
  bl          draw_death
  bl          draw_sprites
  bl          draw_start
  bl          gfx_swap

  bl          update_sound
  bl          update_input

  @ Loop until start is pressed
  ldr         r0, =button_pressed
  ldr         r0, [r0]
  tst         r0, #0x08
  beq         1b

  bl          snd_stop_fail
  bl          reset_enemies
  bl          reset_flares
  bl          reset_rockets 
  bl          reset_objects
  bl          reset_bullets
  bl          reset_player_mov

  b           game_loop

@-------------------------------------------------------------------------------
@ Pause loop
@-------------------------------------------------------------------------------
pause_loop:
  stmfd       sp!, {lr}

1:
  bl          update_input  
  bl          update_sound

  @ Loop until select is pressed
  ldr         r0, =button_clicked
  ldr         r0, [r0]
  tst         r0, #0x04
  beq         1b

  ldmfd       sp!, {pc}  

@ ------------------------------------------------------------------------------
@ Main game loop
@ ------------------------------------------------------------------------------
game_loop:
  bl          setup_player
  bl          setup_enemies
  bl          snd_play_rock

1:
  bl          gfx_swap
  bl          update_input
  
  ldr         r0, =button_clicked
  ldr         r0, [r0]
  tst         r0, #0x04
  blne        pause_loop

  bl          update_player
  bl          update_sound
  bl          draw_pillars
  bl          draw_enemies
  bl          draw_rocks
  bl          draw_bullets
  bl          draw_rockets
  bl          draw_player
  bl          draw_fps
  bl          draw_high_score

  ldr         r0, =player_health
  ldr         r0, [r0]
  cmp         r0, #0
  bgt         1b

  b           death_loop

.section .data
@ ------------------------------------------------------------------------------
@ FPS counter
@ ------------------------------------------------------------------------------
frame_counter:
  .long 0
last_frame:
  .long 0
fps:
  .long 0

.section .text
@ ------------------------------------------------------------------------------
@ Renders the FPS counter on screen
@ ------------------------------------------------------------------------------
draw_fps:
  stmfd       sp!, {lr}

  @ Updates the FPS counter
  ldr         r0, =last_frame
  ldr         r1, [r0]
  ldr         r2, =1000000
  add         r1, r1, r2            @ Update fps once every second

  ldr         r2, =STIMER_CLO       @ Read system timer
  ldr         r2, [r2]

  ldr         r3, =frame_counter    @ Increment frame count
  ldr         r4, [r3]
  add         r4, r4, #1
  str         r4, [r3]

  cmp         r1, r2
  bgt         1f                    @ If 1s passed, update fps
  ldr         r1, =fps
  str         r4, [r1]
  str         r2, [r0]
  mov         r4, #0
1:
  str         r4, [r3]

  @ Renders the FPS on screen
  ldr         r0, =1f
  mov         r1, #15
  mov         r2, #10
  ldr         r3, =0xFFFFFFFF
  ldr         r4, =fps
  ldr         r4, [r4]
  push        {r4}
  ldr         r4, =player_score
  ldr         r4, [r4]
  push        {r4}
  bl          printf
  add         sp, sp, #8

  ldmfd       sp!, {pc}
1:
  .ascii "Score: %5d\nFPS: %2d"
  .byte  0x0
  .align 2

@ ------------------------------------------------------------------------------
@ Renders the high score for this session
@ ------------------------------------------------------------------------------
draw_high_score:
  stmfd       sp!, {lr}
  
  ldr         r0, =1f
  mov         r1, #512
  sub         r1, r1, #23
  mov         r2, #10
  ldr         r3, =0xFFFFFFFF
  ldr         r4, =player_high_score
  ldr         r4, [r4]
  push        {r4}
  bl          printf
  add         sp, sp, #4
  
  ldmfd       sp!, {pc}
1:
  .ascii "High Score: %5d\n"
  .byte 0x0
  .align 2


@ ------------------------------------------------------------------------------
@ Renders the welcome message
@ ------------------------------------------------------------------------------
draw_start:
  stmfd       sp!, {r0 - r3, lr}

  ldr         r0, =1f
  mov         r1, #240
  mov         r2, #400
  ldr         r3, =0xFFFFFFFF
  bl          printf

  ldmfd       sp!, {r0 - r3, pc}
1:
  .ascii "Press START to begin"
  .byte  0x0
  .align 2

@ ------------------------------------------------------------------------------
@ Prints the death message
@ Arguments:
@   r0 - Random number between 0 and number of strings
@ Returns:
@   Nothing
@ ------------------------------------------------------------------------------
draw_death:
  stmfd       sp!, {r0 - r4, lr}

  @ Draw death message text
  ldr         r0, =2f
  add         r0, r0, r1, lsl #6
  ldr         r1, [r0], #4
  mov         r2, #170
  ldr         r3, =0xFFFFFFFF
  bl          printf

  @ Draw score
  ldr         r0, =1f
  mov         r1, #272
  mov         r2, #300
  ldr         r3, =0xFFFFFFFF
  ldr         r4, =player_score
  ldr         r4, [r4]
  push        {r4}
  bl          printf

  add         sp, sp, #4

  ldmfd       sp!, {r0 - r4, pc}
1:
  .ascii "Score: %5d\0"
  .align 2
2:
  death_msg 200, "You have died, what a tragedy!\0"
  death_msg 172, "You have died, better luck next time!\0"
  death_msg 124, "You have died, maybe you should go back to Mario?\0"
  death_msg 184, "You have died, give it another go?\0"

.section .text
@ ------------------------------------------------------------------------------
@ Prints rotating sprites
@ Arguments:
@   none
@ Returns:
@   none
@ Clobbers:
@   s0 - s31
@ ------------------------------------------------------------------------------
draw_sprites:
  stmfd       sp!, {r0 - r4, lr}

  @ Clear model matrix
  ldr         r0, =mtx_id
  vldm.f32    r0, {s0 - s15}
  ldr         r0, =mtx_model
  vstm.f32    r0, {s0 - s15}
  ldr         r0, =mtx_temp
  vstm.f32    r0, {s0 - s15}

  @ Compute the proj - view matrix
  ldr         r0, =0
  vmov.f32    s0, r0
  ldr         r0, =0
  vmov.f32    s1, r0
  ldr         r0, =0xc0e00000
  vmov.f32    s2, r0
  ldr         r0, =mtx_view
  bl          mat4_translate

  ldr         r0, =mtx_proj
  ldr         r1, =mtx_view
  ldr         r2, =mtx_vp
  bl          mat4_mul_mat4

  @ Prepare the model matrix
  ldr         r0, =0x3f800000     @ 1.0
  vmov.f32    s0, r0
  ldr         r0, =0
  vmov.f32    s1, r0
  ldr         r0, =0
  vmov.f32    s2, r0
  ldr         r0, =mtx_model
  bl          mat4_translate

  @ Update rotation around y
  ldr         r0, =1f
  vldr.f32    s0, [r0]
  ldr         r1, =0x3d000000     @ 0.03125
  vmov.f32    s1, r1
  vadd.f32    s0, s1
  vstr.f32    s0, [r0]
  ldr         r0, =mtx_temp
  bl          mat4_rot_y
  ldr         r0, =mtx_temp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_model
  bl          mat4_mul_mat4

  @ Rotate around y by 120 degrees
  ldr         r0, =0x40060a92     @ 2 * PI / 3
  vmov.f32    s0, r0
  ldr         r0, =mtx_temp
  bl          mat4_rot_y

  @ Draw a bullet
  ldr         r0, =mtx_vp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_mvp
  bl          mat4_mul_mat4
  ldr         r0, =bullet
  ldr         r1, =mtx_mvp
  ldr         r2, =mtx_model      @ don't ask me why
  ldr         r3, =0x3e800000
  vmov.f32    s0, r3
  vmov.f32    s1, r3
  bl          gfx_draw_sprite

  @ Draw a rocket
  ldr         r0, =mtx_temp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_model
  bl          mat4_mul_mat4
  ldr         r0, =mtx_vp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_mvp
  bl          mat4_mul_mat4
  ldr         r0, =rocket
  ldr         r1, =mtx_mvp
  ldr         r2, =mtx_model
  ldr         r3, =0x3e800000
  vmov.f32    s0, r3
  vmov.f32    s1, r3
  bl          gfx_draw_sprite

  @ Draw a wrench
  ldr         r0, =mtx_temp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_model
  bl          mat4_mul_mat4
  ldr         r0, =mtx_vp
  ldr         r1, =mtx_model
  ldr         r2, =mtx_mvp
  bl          mat4_mul_mat4
  ldr         r0, =wrench
  ldr         r1, =mtx_mvp
  ldr         r2, =mtx_model
  ldr         r3, =0x3e800000
  vmov.f32    s0, r3
  vmov.f32    s1, r3
  bl          gfx_draw_sprite

  ldmfd       sp!, {r0 - r4, pc}
1:
  .float      0.0
