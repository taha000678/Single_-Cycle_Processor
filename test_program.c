/* test_program.c -- bare-metal, no standard library, no OS */

#define LED_ADDR   ((volatile unsigned int *)0x2000)
#define DMEM_ADDR  ((volatile unsigned int *)0x1000)

int main(void) {
    unsigned int a = 5;
    unsigned int b = 3;
    unsigned int sum = a + b;

    /* store result to data memory */
    DMEM_ADDR[0] = sum;

    /* write a pattern to the LED peripheral */
    *LED_ADDR = 0x55;

    /* simple loop so the LED pattern changes -- good for watching in GTKWave */
    volatile unsigned int i;
    for (i = 0; i < 4; i++) {
        *LED_ADDR = (1 << i);
    }

    return 0;
}