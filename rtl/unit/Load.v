`timescale 1ns/1ps

module Load (
    input MemRead,
    input [1:0] byte_offset,
    input [31:0] DMEM_word,
    input [2:0] funct3,
    output reg [31:0] DMEM_result
);

    wire [31:0] DMEM_shifted_word; // for loads
    assign DMEM_shifted_word = DMEM_word >> 8*byte_offset;

    always @ (*) begin

        if (MemRead) begin

            case (funct3) 
            
                3'b000: DMEM_result = {{24{DMEM_shifted_word[7]}}, DMEM_shifted_word[7:0]}; // LB
                3'b001: DMEM_result = {{16{DMEM_shifted_word[15]}}, DMEM_shifted_word[15:0]}; // LH
                3'b010: DMEM_result = DMEM_shifted_word; // LW
                3'b100: DMEM_result = {24'b0, DMEM_shifted_word[7:0]}; // LBU
                3'b101: DMEM_result = {16'b0, DMEM_shifted_word[15:0]}; // LHU

            endcase

        end


    end


endmodule