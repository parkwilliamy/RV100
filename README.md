# R500
## Features
- R500 is a 32-bit processor based on the RISC-V architecture
- R500 has a CPI of 1.23, branch predictor accuracy of 96.5%, and a throughput of 46.3 million instructions per second
- Implemented on the Xilinx Artix-7 FPGA with 20KB of instruction memory and 12KB of data memory
- Utilizes a 5-stage pipeline with global branch prediction
- Designed a 2-way set associative branch target buffer to eliminate penalties for taken branch instructions

## R500 Architecture
<p align="center">
  <img width="610" height="500" alt="R500_Architecture" src="https://github.com/user-attachments/assets/cc8a34cd-d99a-4182-861c-e690406e79ee" />
</p>

## System Architecture
<p align="center">
  <img width="10892" height="5760" alt="image" src="https://github.com/user-attachments/assets/add98f81-4c2a-4165-946f-8fa9f47eb2f7" />
</p>



## Memory Interface


## Verification

## Performance Testing

## Compliance Test Procedure 

- This project uses the official RISC-V compliance tests with the RISCOF framework for the RV32I ISA
- For more details on the tests, visit https://github.com/riscv-non-isa/riscv-arch-test

<p align="center">
  <img width="730" height="631" alt="RV500_Compliance_Diagram drawio" src="https://github.com/user-attachments/assets/58eba543-c916-4858-a574-bf4facae63a0" />
</p>

