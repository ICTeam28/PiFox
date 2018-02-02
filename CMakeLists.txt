# This file is part of the Team 28 Project
# Licensing information can be found in the LICENSE file
# (C) 2014 The Team 28 Authors. All rights reserved.
cmake_minimum_required(VERSION 2.8)
project(PiFox ASM)

# Find the python interpreter
set( PythonInterp_FIND_VERSION 2 )
find_package( PythonInterp REQUIRED )

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

set( CMAKE_EXECUTABLE_SUFFIX .elf )
set( CMAKE_ASM_FLAGS "-march=armv6zk -mfpu=vfp -g -Wa,--fatal-warnings -nostartfiles -nostdlib" )
set( CMAKE_EXE_LINKER_FLAGS "-Wl,-T,${PROJECT_SOURCE_DIR}/kernel.ld" )
include_directories( ${CMAKE_CURRENT_SOURCE_DIR} )

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
    COMMAND ${PYTHON_EXECUTABLE} ${CMAKE_SOURCE_DIR}/imager.py ${source} --out=${object}
  )

  list(APPEND IMAGES_BIN ${object})
endforeach(file)

# Build a binary file out of the elf
add_executable( kernel ${SOURCES} ${IMAGES_BIN} )

# Without an operating system, there is no executable loader, so we just need
# the raw machine code (or binary) from the ELF output of the toolchain.
# objcopy can do that for us.
add_custom_command(
    TARGET kernel POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} ${CMAKE_BINARY_DIR}/kernel.elf -O binary ./kernel.img
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Convert the ELF output file to a binary image" )
