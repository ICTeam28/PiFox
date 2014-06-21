PiFox
=====

Video of the game in action: https://www.youtube.com/watch?v=-5n9IxSQH1M

Bare Metal 3D rail shooter game

* 5800 lines of ARM assembly (ARMv6 + VFP1)
* Software rasterizer
* 3D objects
* 2D billboards
* Sound using DMA
* NES controller input
* Math & utility library
* GitHub: https://github.com/ICTeam28/PiFox
* Emulator: https://github.com/ICTeam28/PiEmu

Build
-----

The project uses CMake and requires an ARM assembler supporting
GNU as syntax. 

    mkdir build
    cmake ..
    make

PiEmu can run the game without sound. A qemu branch can be used to emulate 
the game at a higher framerate, but sound must be disabled.
(https://github.com/Torlus/qemu/tree/rpi)

config.txt
----------

In order to be compatible with qemu, the kernel must be loaded at address 0x10000.

    disable_overscan=1
    disable_pvt=1
    force_turbo=1
    gpu_mem_256=160
    gpu_mem_512=316
    cma_lwm=16
    cma_hwm=32
    kernel_address=65536

Wiring the controller
---------------------

|    NES   |  Raspberry Pi  |
|:--------:|:--------------:|
| GND      | Ground         |
| VCC      | 3v3            |
| CUP      | GPIO 10        |
| OUT 0    | GPIO 11        |
| D1       | GPIO 4         |

![NES Pinout](https://raw.github.com/ICTeam28/PiFox/master/assets/nes-controller-pinout.png)

![Raspberry PI Pinout](https://raw.github.com/ICTeam28/PiFox/master/assets/raspbery-pi-pinout.png)

Special thanks
--------------

* https://github.com/dwelch67/raspberrypi
* https://github.com/PeterLemon/RaspberryPi
