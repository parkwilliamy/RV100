int main() {

    volatile int* CLK_CYCLE_ADDR = (int*)0x00004F00;
    volatile int* INVALID_CLK_CYCLE_ADDR = (int*)0x00004F04;
    volatile int* RETIRED_INSTRUCTIONS_ADDR = (int*)0x00004F08;
    volatile int* CORRECT_PREDICTIONS_ADDR = (int*)0x00004F0C;
    volatile int* TOTAL_PREDICTIONS_ADDR = (int*)0x00004F10;
    volatile unsigned char* RESULT_ADDR = (unsigned char*)0x00006000;

    RESULT_ADDR[0] = 1;
    RESULT_ADDR[1] = 2;
    RESULT_ADDR[2] = 3;
    RESULT_ADDR[3] = 4;
    
    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 0;
    

    while(1);

}