int main() {

    int count = 0;
    
    for (int i = 0; i < 100000; i++) {
        if ((i&3) != 3) count++;
    }

    volatile int* RESULT_ADDR = (volatile int*)0x00006000;
    *RESULT_ADDR = count;


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

