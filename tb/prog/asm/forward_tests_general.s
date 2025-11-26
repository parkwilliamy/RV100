    .globl _start

    .section .text
_start:
    # Both EX/MEM and MEM/WB

    addi x1, x0, 2
    addi x2, x0, 4
    add x3, x1, x2

    addi x4, x0, 8
    addi x5, x0, 10
    or x6, x4, x5

    addi x7, x0, 14
    addi x8, x0, 16
    sll x9, x7, x8

   
  
    