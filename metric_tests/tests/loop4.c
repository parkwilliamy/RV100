int main() {

    int count = 0;
    
    for (int i = 0; i < 100000; i++) {
        if ((i&3) != 3) count++;
    }

    volatile int* RESULT_ADDR = (volatile int*)0x00006000;

    *RESULT_ADDR = count;

    while(1);

}

