SECTIONS
{
  . = 0x10000;

  /* Executable code */
  .text :
  {
    *(.text)
  }
  . = ALIGN(0x1000);

  /* Data */
  .data :
  {
    *(.data)
  }
  . = ALIGN(0x1000);

  /* Stack space */
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

  /* Front buffer */
  . = . + 640 * 480 * 8;
  gfx_buffer = .;
}
