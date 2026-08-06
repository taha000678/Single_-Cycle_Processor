#define LED_ADDR ((volatile unsigned int *)0x2000)

void delay(void) {
    volatile unsigned int i;
    for (i = 0; i < 3000000; i++) { }
}

int main(void) {
    unsigned int pos = 0;
    unsigned int direction = 0;

    while (1) {
        *LED_ADDR = (1 << pos);
        delay();

        if (direction == 0) {
            if (pos == 3) { direction = 1; pos = 2; }
            else { pos = pos + 1; }
        } else {
            if (pos == 0) { direction = 0; pos = 1; }
            else { pos = pos - 1; }
        }
    }
    return 0;
}
