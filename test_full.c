/* test_full.c -- ek hi program mein saari major RV32I instructions test hoti hain.
 * Har result ek fixed DMEM address pe store hota hai, taake testbench
 * register numbers pe depend na kare (GCC kabhi bhi different register
 * choose kar sakta hai -- lekin memory address hamesha wahi rahega).
 */

#define BASE   ((volatile unsigned int  *)0x1000)
#define BASE8  ((volatile unsigned char *)0x1000)
#define BASE16 ((volatile unsigned short*)0x1000)

int add_func(int x, int y) {
    return x + y;               /* JAL / JALR + stack (ra save/restore) test */
}

int main(void) {
    int a = 10, b = 3;

    BASE[0] = a + b;             /* ADD          -> 13 */
    BASE[1] = a - b;             /* SUB          -> 7  */
    BASE[2] = a & b;             /* AND          -> 2  */
    BASE[3] = a | b;             /* OR           -> 11 */
    BASE[4] = a ^ b;             /* XOR          -> 9  */
    BASE[5] = a << 2;            /* SLL          -> 40 */
    BASE[6] = a >> 1;            /* SRA/SRL      -> 5  */

    int cmp = 0;
    if (a > b)   cmp |= 0x1;     /* SLT/BLT/BGE path -> taken     */
    if (a == 10) cmp |= 0x2;     /* BEQ path         -> taken     */
    if (b != 3)  cmp |= 0x4;     /* BNE path         -> NOT taken */
    BASE[7] = cmp;               /* expect 0x3 */

    int sum = 0;
    for (int i = 0; i < 10; i++) {
        sum += i;                /* loop -> branch-back (BLT/BGE) test */
    }
    BASE[8] = sum;                /* expect 45 */

    BASE[9] = add_func(a, b);     /* function call -> expect 13 */

    unsigned int ua = 5, ub = 300000000;
    int ucmp = 0;
    if (ua < ub) ucmp |= 0x1;     /* BLTU test (would be wrong if done as signed) */
    BASE[10] = ucmp;              /* expect 1 */

    BASE8[100]  = 0xAB;                    /* SB  */
    BASE[11]    = BASE8[100];              /* LBU -> expect 0xAB */

    BASE16[52]  = 0xBEEF;                  /* SH  (offset 104 bytes) */
    BASE[12]    = BASE16[52];              /* LHU -> expect 0xBEEF */

    BASE[13] = 0xDEADBEEF;        /* "program finished" marker */

    /* ---- GPIO test ---- */
    #define GPIO_OUT ((volatile unsigned int *)0x2000)
    #define GPIO_IN  ((volatile unsigned int *)0x2004)

    *GPIO_OUT = 0xA5A5A5A5;       /* drive a known pattern out */
    BASE[14]  = *GPIO_OUT;        /* read it back -> expect 0xA5A5A5A5 */
    BASE[15]  = *GPIO_IN;         /* read external input pins (testbench-driven) */

    return 0;
}