/* linker.ld -- Single-Cycle RISC-V SoC (Wishbone) memory map
 * Program mem base : 0x00000000
 * Data mem base    : 0x00001000
 * LED base         : 0x00002000  (peripheral, not part of linked memory)
 */

MEMORY
{
    PROG (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    DATA (rwx) : ORIGIN = 0x00001000, LENGTH = 4K
}

ENTRY(_start)

SECTIONS
{
    .text : {
        *(.text.start)   /* crt0.s ka start code sabse pehle aaye */
        *(.text*)
    } > PROG

    .rodata : {
        *(.rodata*)
    } > PROG

    .data : {
        *(.data*)
    } > DATA

    .bss : {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > DATA

    /* Stack data-memory ke end pe rakhi hai, neeche ki taraf grow karti hai */
    _stack_top = ORIGIN(DATA) + LENGTH(DATA);
}