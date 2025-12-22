int main() {

    volatile unsigned char* RESULT_ADDR = (volatile unsigned char*)0x6000;

    RESULT_ADDR[0] = 1;
    RESULT_ADDR[1] = 2;
    RESULT_ADDR[2] = 3;
    RESULT_ADDR[3] = 4;

    volatile int* CLK_CYCLE_ADDR = (volatile int*)0x00005000;
    volatile int* INVALID_CLK_CYCLE_ADDR = (volatile int*)0x00005004;
    volatile int* RETIRED_INSTRUCTIONS_ADDR = (volatile int*)0x00005008;
    volatile int* CORRECT_PREDICTIONS_ADDR = (volatile int*)0x0000500C;
    volatile int* TOTAL_PREDICTIONS_ADDR = (volatile int*)0x00005010;
    
    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 0;
    

    while(1);

}