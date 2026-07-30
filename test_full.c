
#define BASE   ((volatile unsigned int  *)0x1000)
#define BASE8  ((volatile unsigned char *)0x1000)
#define BASE16 ((volatile unsigned short*)0x1000)

int add_func(int x, int y) {
    return x + y;               
}

int main(void) {
    int a = 10, b = 3;

    BASE[0] = a + b;             
    BASE[1] = a - b;         
    BASE[2] = a & b;             
    BASE[3] = a | b;             
    BASE[4] = a ^ b;           
    BASE[5] = a << 2;            
    BASE[6] = a >> 1;            

    int cmp = 0;
    if (a > b)   cmp |= 0x1;     
    if (a == 10) cmp |= 0x2;     
    if (b != 3)  cmp |= 0x4;     
    BASE[7] = cmp;               

    int sum = 0;
    for (int i = 0; i < 10; i++) {
        sum += i;                /
    }
    BASE[8] = sum;                

    BASE[9] = add_func(a, b);    

    unsigned int ua = 5, ub = 300000000;
    int ucmp = 0;
    if (ua < ub) ucmp |= 0x1;     
    BASE[10] = ucmp;              

    BASE8[100]  = 0xAB;                    
    BASE[11]    = BASE8[100];              

    BASE16[52]  = 0xBEEF;                  
    BASE[12]    = BASE16[52];              

    BASE[13] = 0xDEADBEEF;       

    return 0;
}