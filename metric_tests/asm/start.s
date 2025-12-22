.section .text.startup
.globl _start
_start:
    # 1) Initialize stack
    la   sp, _stack_top
    addi sp, sp, -16     # align

    # 2) Copy .data from IMEM to DMEM
    la   t0, __data_load_start
    la   t1, __data_start
    la   t2, __data_end
1:
    beq  t1, t2, 2f
    lw   t3, 0(t0)
    sw   t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j    1b
2:
    # 3) Zero .bss
    la   t1, __bss_start
    la   t2, __bss_end
3:
    beq  t1, t2, 4f
    sw   x0, 0(t1)
    addi t1, t1, 4
    j    3b
4:
    # 4) Call main
    call main

5:
    # 5) No OS → spin forever
    j 5b
