SECTIONS
{
  /**
   * Start address of the kernel.
   *
   * In QEMU, this is hardcoded to 0x100000 (64Kb).
   * On the actual device, it can be modified, but it defaults to 0x8000 (32Kb).
   */
  . = 0x10000;

  /**
   * Executable code. 
   * 
   * All text segments are copied here. The first file in the object file
   * is kernel.s and the first function in kernel.s is the kernel function
   * which initializes everything, so it gets placed at the start address
   * by the bootstrap code. After the text segment, padding is added in
   * order to align the next segment to a page boundary.
   */
  .text :
  {
    *(.text)
  }
  . = ALIGN(0x1000);

  /**
   * Program data, all .data segments concatenated after each other. Padding
   * is added afterwards to align the next segment to page boundary.
   */
  .data :
  {
    *(.data)
  }
  . = ALIGN(0x1000);

  /**
   * Stack spaces. These come after the data from the binary file,
   * thus they are not actually present in it. They are not loaded,
   * but the addresses are set up for them after the file. If the
   * length of the file is x, then the stack addresses are located
   * at the page boundary after x + 64Kb.
   */
  . = . + 0x800;
  stack_svc = .;
  . = . + 0x800;
  stack_und = .;
  . = . + 0x800;
  stack_abt = .;
  . = . + 0x800;
  stack_irq = .;
  . = . + 0x800;
  stack_fiq = .;
  . = . + 0x400000;
  stack_sys = .;

  /**
   * Front buffer. Since this buffer is quite large, around 2Mb in size,
   * it should not appear in the binary file since it would increase the
   * time it takes to load the kernel. Thus, the address space it requires
   * is only defined in the linker script and placed at the end of the
   * kernel, after all data that is loaded from the binary file.
   */
  . = . + 640 * 480 * 8;
  gfx_buffer = .;
}
