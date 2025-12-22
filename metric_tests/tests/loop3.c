int main() {

    int count = 0;
    int flag = 0;
    
    for (int i = 0; i < 1000; i++) {
        if (flag % 2 == 0 || flag % 3 == 0 || flag % 5 == 0) count++;
        flag++;
    }

    volatile int* RESULT_ADDR = (volatile int*)0x00006000;

    *RESULT_ADDR = count;

    while(1);

}