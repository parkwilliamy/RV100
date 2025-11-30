`timescale 1ns/1ps

module Fetch(
    input Branch, branch_taken, Jump, ALUSrc,
    input [31:0] pc, imm, rs1_data,
    output reg [31:0] next_pc
);

    always @ (*) begin
        
        // Branch Instruction Logic
        if (Branch && branch_taken) next_pc = pc+imm;
        // Jump Instruction Logic
        else if (Jump) begin 
            if (ALUSrc == 0) next_pc = pc+imm; // JAL
            else next_pc = (rs1_data+imm) & 32'hFFFFFFFE; // JALR, clear lsb to ensure word alignment
        end
        else next_pc = pc+4;

    end


endmodule