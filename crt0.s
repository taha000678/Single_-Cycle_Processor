/* crt0.s -- reset ke baad sabse pehle chalne wala code */

.section .text.start
.global _start

_start:
    /* Step 1: Stack pointer set karo (linker.ld se aaya address) */
    la sp, _stack_top

    /* Step 2: .bss section ko zero se fill karo (uninitialized globals) */
    la t0, _bss_start
    la t1, _bss_end
bss_clear_loop:
    bge t0, t1, bss_clear_done
    sw  zero, 0(t0)
    addi t0, t0, 4
    j bss_clear_loop
bss_clear_done:

    /* Step 3: main() ko call karo */
    call main

    /* Step 4: main() return kar jaye to yahan hamesha ke liye ruk jao (halt) */
halt:
    j halt