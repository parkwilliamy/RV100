    .globl _start

    .section .text
_start:
    # MEM/WB forwarding

    # rs1 tests
    addi x1, x0, 2
    addi x0, x0, 0
    add x2, x1, x0

    addi x3, x0, 6
    addi x0, x0, 0
    or x4, x3, x0

    addi x5, x0, 10
    addi x0, x0, 0
    slli x6, x5, 2

    # rs2 tests

    addi x7, x0, 14
    addi x0, x0, 0
    add x8, x0, x7

    addi x9, x0, 18
    addi x0, x0, 0
    or x10, x0, x9

    addi x11, x0, 22
    addi x0, x0, 0
    sll x12, x1, x11

    # both
    
    addi x13, x0, 26
    addi x0, x0, 0
    add x14, x13, x13

    addi x15, x0, 30
    addi x0, x0, 0
    or x16, x15, x15

    addi x17, x0, 34
    addi x0, x0, 0
    sll x18, x17, x17
   
    