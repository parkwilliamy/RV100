/*

int main() {

    //volatile int a,b,c,d,e,f,g,h;
    volatile int a,b;

    a = 0;
    b = 0;

    a = 20;
    b = a ^ 1;
    /*
    c = 1;
    d = c+2;

    e = 5;
    f = e-1;

    g = 2;
    h = g | 0;
    
    volatile int* RESULT_ADDR = (volatile int*)0x6000;

    RESULT_ADDR[0] = b;
    RESULT_ADDR[1] = d;
    RESULT_ADDR[2] = f;
    RESULT_ADDR[3] = h;
    
    while(1);

}

*/

int main() {

    volatile unsigned char* RESULT_ADDR = (volatile unsigned char*)0x6000;

    RESULT_ADDR[0] = 1;
    RESULT_ADDR[1] = 2;
    RESULT_ADDR[2] = 3;
    RESULT_ADDR[3] = 4;

    volatile int* CLK_CYCLE_ADDR = (volatile int*)0x00007000;
    volatile int* INVALID_CLK_CYCLE_ADDR = (volatile int*)0x00007004;
    volatile int* RETIRED_INSTRUCTIONS_ADDR = (volatile int*)0x00007008;
    volatile int* CORRECT_PREDICTIONS_ADDR = (volatile int*)0x0000700C;
    volatile int* TOTAL_PREDICTIONS_ADDR = (volatile int*)0x00007014;
    
    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 0;
    

    while(1);

}