`timescale 1ns/1ps

module LSU (
    input MemWrite, MemRead,
    input [31:0] addrb, DMEM_word, rs2_data,
    input [2:0] EX_funct3, MEM_funct3,
    output reg [3:0] web,
    output reg [31:0] dib, DMEM_result
);

    wire [1:0] byte_offset;
    assign byte_offset = addrb % 4;

    wire [31:0] DMEM_shifted_word; // for loads
    assign DMEM_shifted_word = DMEM_word >> 8*byte_offset;

    always @ (*) begin

        dib = 0;
        web = 0;

        if (MemWrite) begin

                case (EX_funct3) 

                    3'b000: begin // SB
                        
                        web = (4'b0001 << byte_offset);
                        dib[7+8*byte_offset -: 8] = rs2_data[7:0]; 

                    end

                    3'b001: begin // SH

                        web = (4'b0011 << byte_offset);
                        dib[15+8*byte_offset -: 16] = rs2_data[15:0]; 
                    
                    end

                    3'b010: begin // SW

                        web = 4'b1111;
                        dib = rs2_data;

                    end
                
                endcase
             
        end

        else if (MemRead) begin

            case (MEM_funct3) 
            
                3'b000: DMEM_result = {{24{DMEM_shifted_word[7]}}, DMEM_shifted_word[7:0]}; // LB
                3'b001: DMEM_result = {{16{DMEM_shifted_word[15]}}, DMEM_shifted_word[15:0]}; // LH
                3'b010: DMEM_result = DMEM_shifted_word; // LW
                3'b100: DMEM_result = {24'b0, DMEM_shifted_word[7:0]}; // LBU
                3'b101: DMEM_result = {16'b0, DMEM_shifted_word[15:0]}; // LHU

            endcase

        end


    end


endmodule