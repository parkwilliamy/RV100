`timescale 1ns/1ps

module ForwardUnit (
    input [31:0] MEM_ALU_result, MEM_pc, MEM_pc_imm, WB_rd_write_data,
    input [1:0] MEM_RegSrc,
    input [4:0] EX_rs1, EX_rs2, MEM_rd, WB_rd,
    input [2:0] EX_ValidReg, MEM_ValidReg, WB_ValidReg,
    output rs1_fwd, rs2_fwd,
    output reg [31:0] rs1_fwd_data, rs2_fwd_data
);

    wire rs1_MEM_fwd, rs2_MEM_fwd, rs1_WB_fwd, rs2_WB_fwd;
    reg [31:0] MEM_rd_write_data;

    assign rs1_MEM_fwd = (EX_rs1 == MEM_rd) && (EX_ValidReg[1] && MEM_ValidReg[0]);
    assign rs2_MEM_fwd = (EX_rs2 == MEM_rd) && (EX_ValidReg[2] && MEM_ValidReg[0]);
    assign rs1_WB_fwd = (EX_rs1 == WB_rd) && (EX_ValidReg[1] && WB_ValidReg[0]);
    assign rs2_WB_fwd = (EX_rs2 == WB_rd) && (EX_ValidReg[2] && WB_ValidReg[0]);

    assign rs1_fwd = (rs1_MEM_fwd || rs1_WB_fwd) && (EX_rs1 != 0);
    assign rs2_fwd = (rs2_MEM_fwd || rs2_WB_fwd) && (EX_rs2 != 0);

    always @ (*) begin

        case (MEM_RegSrc)

            0: MEM_rd_write_data = MEM_ALU_result;
            2: MEM_rd_write_data = MEM_pc_imm;
            3: MEM_rd_write_data = MEM_pc+4;

        endcase

        if (rs1_MEM_fwd) rs1_fwd_data = MEM_rd_write_data;
        if (rs2_MEM_fwd) rs2_fwd_data = MEM_rd_write_data;

        if (rs1_WB_fwd) begin
            if (rs1_MEM_fwd) begin
                if (MEM_rd != WB_rd) rs1_fwd_data = WB_rd_write_data;
                else rs1_fwd_data = MEM_rd_write_data;
            end
            else rs1_fwd_data = WB_rd_write_data;
        end

        if (rs2_WB_fwd) begin
            if (rs2_MEM_fwd) begin
                if (MEM_rd != WB_rd) rs2_fwd_data = WB_rd_write_data;
                else rs2_fwd_data = MEM_rd_write_data;
            end
            else rs2_fwd_data = WB_rd_write_data;
        end

    end


endmodule