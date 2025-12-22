int fib(int n) {

    if (n == 0 || n == 1) return n;
    else return fib(n-1) + fib(n-2);

}

int main() {

    int x = fib(15);
    *(volatile int*)0x5000 = x;


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

    while (1);

}

