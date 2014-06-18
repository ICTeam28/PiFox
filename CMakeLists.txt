# This file is part of the Team 28 Project
# Licensing information can be found in the LICENSE file
# (C) 2014 The Team 28 Authors. All rights reserved.
cmake_minimum_required(VERSION 2.8)
project(PiFox)

set(SOURCES
  kernel.s
  math.s
  mbox.s
  gfx.s
  ports.s
  input.s
  printf.s
  game.s
  bullets.s
  objects.s
  pillars.s
  player.s
  sound.s
  rockets.s
  enemies.s
  assets/rock.s
  assets/ship.s
  assets/enemy.s
  assets/rocket.s
)

SET(IMAGES
  bullet.png
  rocket.png
  wrench.png
  flare.png
  mountains.png
  tristan.png
  monkey.png
  pifox.png
)

set(ASFLAGS -march=armv6zk -mfpu=vfp -g --fatal-warnings)

# Determine toolchain
execute_process(COMMAND which arm-none-eabi-as OUTPUT_VARIABLE NONE_EABI_EXISTS)
message(STATUS ${NONE_EABI_EXISTS})
if(NONE_EABI_EXISTS STREQUAL "")
  set(TOOLCHAIN arm-linux-gnueabi)
else()
  set(TOOLCHAIN arm-none-eabi)
endif()

# Compile all images
foreach(file ${IMAGES})
  get_filename_component(file_path ${file} PATH)
  get_filename_component(file_name ${file} NAME_WE)

  set(file "${file_name}")
  set(object "${CMAKE_BINARY_DIR}/assets${file_path}/${file_name}.bin")
  set(source "${CMAKE_SOURCE_DIR}/assets${file_path}/${file_name}.png")
  get_filename_component(dir ${object} PATH)

  file(MAKE_DIRECTORY ${dir})
  add_custom_command(
    OUTPUT ${object}
    DEPENDS ${source}
    COMMAND ${CMAKE_SOURCE_DIR}/imager.py ${source} --out=${object}
  )

  list(APPEND IMAGES_BIN ${object})
endforeach(file)

# Compile all sources
foreach(file ${SOURCES})
  get_filename_component(file_path ${file} PATH)
  get_filename_component(file_name ${file} NAME_WE)

  set(file "${file_name}")
  set(object "${CMAKE_BINARY_DIR}/${file_path}/${file_name}.o")
  set(source "${CMAKE_SOURCE_DIR}/${file_path}/${file_name}.s")
  get_filename_component(dir ${object} PATH)

  file(MAKE_DIRECTORY ${dir})
  add_custom_command(
    OUTPUT ${object}
    DEPENDS ${source} ${IMAGES_BIN} ${MAPS_BIN}
    COMMAND ${TOOLCHAIN}-as
      ${ASFLAGS} ${source} -o ${object}
      -I${CMAKE_SOURCE_DIR}/
  )

  list(APPEND OBJECTS ${object})
endforeach(file)

# Kernel elf file
set(KERNEL_ELF ${CMAKE_BINARY_DIR}/kernel.elf)
set(KERNEL_LD ${CMAKE_SOURCE_DIR}/kernel.ld)
set(KERNEL_BIN ${CMAKE_BINARY_DIR}/kernel.img)

# Build a binary file out of the elf
add_custom_target(
  kernel ALL
  DEPENDS ${KERNEL_ELF}
  COMMAND ${TOOLCHAIN}-objcopy
    -O binary ${KERNEL_ELF} ${KERNEL_BIN}
)

# Link objects into an elf file
add_custom_command(
  OUTPUT ${KERNEL_ELF}
  DEPENDS ${OBJECTS} ${KERNEL_LD}
  COMMAND ${TOOLCHAIN}-ld
    -T ${KERNEL_LD} ${OBJECTS} -o ${KERNEL_ELF}
)
