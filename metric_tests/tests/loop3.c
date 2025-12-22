static inline int mod(int a, int b) {

    while (a >= b) a-=b;
    return a;

}

int main() {

    int count = 0;
    
    for (int i = 0; i < 1000; i++) {
        if (mod(i,2) == 0 || mod(i,3) == 0 || mod(i,5) == 0) count++;
    }

    volatile int* RESULT_ADDR = (volatile int*)0x00006000;
    *RESULT_ADDR = count;


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

