    .globl _start

    .section .text
_start:
    # EX/MEM forwarding

    # rs1 tests
    addi x1, x0, 2
    add x2, x1, x0

    addi x3, x0, 6
    or x4, x3, x0

    addi x5, x0, 10
    slli x6, x5, 2

    # rs2 tests

    addi x7, x0, 14
    add x8, x0, x7

    addi x9, x0, 18
    or x10, x0, x9

    addi x11, x0, 22
    sll x12, x1, x11

    # both
    
    addi x13, x0, 26
    add x14, x13, x13

    addi x15, x0, 30
    or x16, x15, x15

    addi x17, x0, 34
    sll x18, x17, x17
   
    