`timescale 1ns/1ps

module ForwardUnit (
    input [31:0] MEM_rd_write_data, WB_rd_write_data,
    input [4:0] EX_rs1, EX_rs2, MEM_rd, WB_rd,
    input [2:0] EX_ValidReg, MEM_ValidReg, WB_ValidReg,
    output rs1_fwd, rs2_fwd,
    output reg [31:0] rs1_fwd_data, rs2_fwd_data
);

    wire rs1_MEM_fwd, rs2_MEM_fwd, rs1_WB_fwd, rs2_WB_fwd;

    assign rs1_MEM_fwd = (EX_rs1 == MEM_rd) && (EX_ValidReg[1] && MEM_ValidReg[0]);
    assign rs2_MEM_fwd = (EX_rs2 == MEM_rd) && (EX_ValidReg[2] && MEM_ValidReg[0]);
    assign rs1_WB_fwd = (EX_rs1 == WB_rd) && (EX_ValidReg[1] && WB_ValidReg[0]);
    assign rs2_WB_fwd = (EX_rs2 == WB_rd) && (EX_ValidReg[2] && WB_ValidReg[0]);

    assign rs1_fwd = (rs1_MEM_fwd || rs1_WB_fwd);
    assign rs2_fwd = (rs2_MEM_fwd || rs2_WB_fwd);

    always @ (*) begin

        if (rs1_MEM_fwd) rs1_fwd_data = MEM_rd_write_data;
        if (rs2_MEM_fwd) rs2_fwd_data = MEM_rd_write_data;
        if (rs1_WB_fwd) rs1_fwd_data = WB_rd_write_data;
        if (rs2_WB_fwd) rs2_fwd_data = WB_rd_write_data;

    end


endmodule