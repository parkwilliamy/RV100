# R500
## Features
- R500 is a 32-bit processor based on the RISC-V architecture
- R500 is 100% compliant with the RV32I ISA based on the official compliance test suite (see below for more details)
- R500 has an average CPI of 1.23*, branch predictor accuracy of 96.5%**, and a throughput of 46.3 million instructions per second*
- Implemented on the Xilinx Artix-7 FPGA with 20KB of instruction memory and 12KB of data memory
- Utilizes a 5-stage pipeline with data forwarding, stalling, flushing, and global branch prediction
- Designed a 2-way set associative branch target buffer to eliminate penalties for correctly predicted branch instructions

**Average CPI and throughput were calculated on the average results of loop1.c, loop2.c, loop3.c, loop4.c, loop5.c, fib.c, and mem2.c*

***Average branch predictor accuracy was calculated on the average result of loop1.c, loop2.c, loop3.c, loop4.c, loop5.c*

## Repository Structure
- main branch only contains the files for the synthesized R500
- pipelined branch contains both the files for the simulated R500 and testbenches
- single_cycle branch contains the files for the simulated single cycle R500 and testbenches (this was the original version before I pipelined the design)

## R500 Architecture
<p align="center">
  <img width="660" height="570" alt="R500_Architecture (4)" src="https://github.com/user-attachments/assets/cf5a9d19-2326-42c5-bff0-6d15808d3878" />
</p>

### Hazard Detection
R500's Forward Unit eliminates the following data hazards:

1) MEM to EX
2) WB to EX
3) WB to MEM (only for load-store cases)
   
- The Forward Unit prioritizes the newest data that comes in to a register when there are conflicts in situations like the following:

```
addi x1, x2, 5  # x1 = x2 + 5
addi x1, x1, 3  # x1 = x1 + 3
addi x1, x1, 4  # x1 = x1 + 4 <--- In this case, this instruction must prioritize the data forwarded from the instruction immediately before it, since there is a conflict with the first instruction's x1 data as well
```

- The Stall Unit handles load-use hazards by inserting a single cycle NOP instruction into the pipeline 

### Branch Prediction
The R500's global branch predictor uses gshare indexing, which uses both the PC and global prediction history to map a branch instruction to a prediction

- The Branch History Table (BHT) stores 2-bit predictions for up to 256 unique instructions
- The Branch Target Buffer (BTB) stores the computed target addresses to jump to for up to 32 different instructions
- Together, the BHT and BTB are accessed in the IF stage to determine the next PC as early as possible
- The Branch Resolution Unit (BRU) is later used in the EX stage to determine if the prediction was indeed correct or not; incorrect predictions result in pipeline flushes which are asserted by the Fetch Unit

## System Architecture
<p align="center">
  <img width="2840" height="1610" alt="R500_Top_Architecture drawio" src="https://github.com/user-attachments/assets/7db3bd53-78de-4f4d-ad15-6cf882c1f1e4" />
</p>

### UART
- The UART module handles transmission and reception of data between RAM and the Host PC
- On the RX line, the received data bits are packed into one data byte that is sent to the MemAccess module
- On the TX line, the module unpacks a byte of data into bits to send over this line
- In other words, RX packs bits into a byte while TX unpacks a byte into bits

### MemAccess
- The MemAccess module directly interacts with RAM 
- Packs received bytes into message frames, which then correspond to a read or write operation
- Unpacks data words into bytes to be sent over UART (for read operations)

## Memory Interface
- Memory is in the form of True Dual-Port BRAM
- To interact with BRAM, I designed a UART based interface that accepts read and write messages (interface assumes little-endian behaviour)
- To see how I used this interface, go to scripts/mem_access.py
  
NOTE: Write enable bits select which bytes in a word to write (i.e., we = 0010 will only write the second least significant byte)
### Read Message Format
- When reading from RAM, you must provide ADDR_LOW and ADDR_HIGH to define the region of memory you want to read from
  
1) Send a READ_START byte (0xFF)
2) Send 2 ADDR_HIGH bytes
3) Send 2 ADDR_LOW bytes

<p align="center">
  <img width="3724" height="204" alt="image" src="https://github.com/user-attachments/assets/80d1e4b7-9b17-48ea-8adb-dda0450695d4" />
</p>


### Write Message Format
- When writing to RAM, you must provide the address to write, the write enable bits, and the data word

1) Send a WRITE_START byte (0x0F)
2) Send 2 address bytes
3) Send 1 write enable byte
4) Send 4 data bytes

<p align="center">
  <img width="5284" height="204" alt="image" src="https://github.com/user-attachments/assets/4b2c9079-56f7-4da7-af6e-c609415f0a5a" />
</p>


   
## Verification
NOTE: Testbench files are in the pipelined branch in tb/

- Wrote testbenches in SystemVerilog that implemented constraint random verification along with directed tests
- Debugged waveforms with Vivado's xsim tool
- Wrote a shell script to simplify compilation, elaboration, and simulation into one command
- Utilized Verilator to quickly compile tests that required large amounts of memory (1MB+)
- For more system-wide tests, I wrote assembly and C programs to test basic instructions as well as hazards

## Performance Testing

NOTE: Performance tests located in metric_tests/tests
- These tests are only meant to give a reasonable estimate of the R500's performance

### Loop Tests
- loop1.c tests a basic for loop to provide a baseline for performance 
- loop2.c tests an alternating loop (i.e., branch not taken, branch taken) to test the predictor's ability to recognize a simple pattern
- loop3.c tests a condition based on divisibility by 2,3, or 5 for a large range of numbers; this test provides a more difficult pattern for the predictor
- loop4.c tests a "3 out of 4 taken" pattern; similar to loop3.c, this test provides a moderately difficult pattern to stress test the predictor
- loop5.c tests correlation between 2 branches, provides a different type of pattern from the previous ones to see how to predictor adapts to it
  
| Test     | loop1.c | loop2.c | loop3.c | loop4.c | loop5.c | 
|:----------:|:----------:|:----------:|:----------:|:----------:|:----------:|
| CPI  | 1.2  | 1.16  | 1.28  | 1.21  | 1.28  | 
| Accuracy  | 99.9%  | 99.9%  | 99.3%  | 99.9%  | 83.3%  |

### General Tests
- fib.c tests recursion and processors' ability to handle multiple stack frames
- mem2.c stress tests the processors' load and store instructions

| Test | fib.c | mem2.c |
|:----:|:----:|:----:|
| CPI  | 1.13  | 1.32  |
| Accuracy  | 92.2%  | 97.4%  |


## Compliance Test Procedure 

- This project uses the official RISC-V compliance tests with the RISCOF framework for the RV32I ISA
- For more details on the tests, visit https://github.com/riscv-non-isa/riscv-arch-test

<p align="center">
  <img width="730" height="631" alt="RV500_Compliance_Diagram drawio" src="https://github.com/user-attachments/assets/58eba543-c916-4858-a574-bf4facae63a0" />
</p>

