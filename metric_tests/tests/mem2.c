int main() {

    volatile int* A = (volatile int*)0x5000;
    volatile int* RESULT_ADDR = (volatile int*)0x6000;
    int idx = 0;

    for (int i=0; i < 256; i++) A[i] = i;

    for (int i=0; i < 512; i++) {
        idx = i & 255;
        RESULT_ADDR[idx] = A[idx] + i;
    }
    /*
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
    */

    while(1);

}