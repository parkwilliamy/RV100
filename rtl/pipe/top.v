`timescale 1ns/1ps

module top (
    input rst_n, clk
);

    // ************************************* MEMORY ************************************* 

    reg [3:0] wea, web;
    wire [31:0] addra, addrb, doa, dob; // Port A is IMEM, Port B is DMEM
    reg [31:0] dia, dib;

    // byte addressable memory that uses the nearest word as an index
    BRAM INST1 ( 
        .clk(clk),
        .wea(wea),
        .web(web),
        .addra(addra),
        .addrb(addrb),
        .dia(dia),
        .dib(dib),
        .doa(doa),
        .dob(dob)
    );

    // ******************************** PIPELINE REGISTERS ******************************

    reg [31:0] IF_ID; 
    reg [149:0] ID_EX; 
    reg [107:0] EX_MEM; 

    // *********************************** MODULES **************************************
               
    // =============================== INSTRUCTION FETCH ================================

    reg [31:0] IF_pc;

    assign addra = IF_pc;

    // =============================== INSTRUCTION DECODE ===============================

    wire [31:0] ID_instruction;
    wire [31:0] ID_pc;
    wire [6:0] ID_opcode;
    wire [11:7] ID_rd;
    wire [14:12] ID_funct3;
    wire [19:15] ID_rs1;
    wire [24:20] ID_rs2;
    wire [31:25] ID_funct7;

    assign ID_instruction = doa;
    assign ID_pc = IF_ID;
    assign ID_opcode = ID_instruction[6:0];
    assign ID_rd = ID_instruction[11:7];
    assign ID_funct3 = ID_instruction[14:12];
    assign ID_rs1 = ID_instruction[19:15];
    assign ID_rs2 = ID_instruction[24:20];
    assign ID_funct7 = ID_instruction[31:25];

    wire [1:0] ID_ALUOp; // EX
    wire [1:0] ID_RegSrc; // WB
    wire ID_ALUSrc, ID_RegWrite, ID_MemRead, ID_MemWrite, ID_Branch, ID_Jump; // EX, WB, MEM, MEM, WB, MEM, MEM
    wire [3:0] ID_field;
    wire [31:0] ID_eximm;
    wire [31:0] ID_rs1_data;
    wire [31:0] ID_rs2_data;

    wire MEM_RegWrite;
    wire [4:0] MEM_rd;
    reg [31:0] MEM_rd_write_data;

    ControlUnit INST2 (
        .opcode(ID_opcode), 
        .ALUOp(ID_ALUOp), 
        .RegSrc(ID_RegSrc), 
        .ALUSrc(ID_ALUSrc), 
        .RegWrite(ID_RegWrite), 
        .MemRead(ID_MemRead), 
        .MemWrite(ID_MemWrite), 
        .Branch(ID_Branch),
        .Jump(ID_Jump)
    );

    RegFile INST3 (
        .clk(clk), 
        .RegWrite(MEM_RegWrite), 
        .rs1(ID_rs1), 
        .rs2(ID_rs2), 
        .rd(MEM_rd), 
        .rd_write_data(MEM_rd_write_data), 
        .rs1_data(ID_rs1_data), 
        .rs2_data(ID_rs2_data)
    );

    ImmGen INST4 (
        .instruction(ID_instruction), 
        .eximm(ID_eximm)
    );

    ALUControl INST5 (
        .funct7(ID_funct7), 
        .funct3(ID_funct3), 
        .ALUOp(ID_ALUOp), 
        .regbit(ID_opcode[5]), 
        .field(ID_field)
    );
    

    // ==================================== EXECUTE =====================================

    wire EX_zero, EX_sign, EX_overflow, EX_carry;
    
    wire [3:0] EX_field;
    wire [2:0] EX_funct3;
    wire [1:0] EX_ALUOp; 
    wire [1:0] EX_RegSrc; 
    wire EX_ALUSrc, EX_RegWrite, EX_MemRead, EX_MemWrite, EX_Branch, EX_Jump;
    wire [31:0] EX_pc;
    wire [31:0] EX_rs1_data;
    wire [31:0] EX_rs2_data;
    wire [31:0] EX_eximm;
    wire [4:0] EX_rd;

    wire [31:0] EX_op1;
    wire [31:0] EX_op2;

    assign {
        EX_pc,
        EX_funct3,
        EX_field, 
        EX_ALUOp, 
        EX_RegSrc, 
        EX_ALUSrc,
        EX_RegWrite, 
        EX_MemRead, 
        EX_MemWrite, 
        EX_Branch, 
        EX_Jump,
        EX_rs1_data,
        EX_rs2_data,
        EX_eximm,
        EX_rd
    } = ID_EX;


    assign EX_op1 = (EX_ALUOp == 1 && EX_ALUSrc == 1 && EX_RegSrc == 0 && EX_RegWrite == 1) ? 0 : EX_rs1_data;
    assign EX_op2 = EX_ALUSrc ? EX_eximm : EX_rs2_data;
    wire [31:0] EX_ALU_result;

    ALU INST6 (
        .op1(EX_op1), 
        .op2(EX_op2), 
        .field(EX_field), 
        .ALU_result(EX_ALU_result), 
        .zero(EX_zero), 
        .sign(EX_sign), 
        .overflow(EX_overflow), 
        .carry(EX_carry)
    );

    wire EX_branch_taken;

    BPU INST7 (
        .Branch(EX_Branch),
        .zero(EX_zero),
        .sign(EX_sign),
        .overflow(EX_overflow),
        .carry(EX_carry),
        .funct3(EX_funct3),
        .branch_taken(EX_branch_taken)
    );

    wire [31:0] EX_pc_eximm;
    assign EX_pc_eximm = EX_pc + EX_eximm;


    // ================================== MEMORY WRITE ==================================


    wire [31:0] MEM_pc;
    wire [2:0] MEM_funct3;
    wire [1:0] MEM_RegSrc; 
    wire MEM_MemRead;
    
    wire [31:0] MEM_pc_eximm;
    wire [31:0] MEM_ALU_result;

    assign {
        MEM_pc,
        MEM_pc_eximm,
        MEM_funct3, 
        MEM_RegSrc, 
        MEM_RegWrite, 
        MEM_MemRead,  
        MEM_ALU_result,
        MEM_rd
    } = EX_MEM;

    assign addrb = EX_ALU_result;

    reg [31:0] MEM_DMEM_result; // properly formatted data for load instructions

    LSU INST8 (
        .MemWrite(EX_MemWrite),
        .MemRead(MEM_MemRead),
        .addrb(addrb),
        .DMEM_word(dob), // data at nearest word aligned address near a given byte address
        .rs2_data(EX_rs2_data),
        .EX_funct3(EX_funct3),
        .MEM_funct3(MEM_funct3),
        .web(web),
        .dib(dib),
        .DMEM_result(MEM_DMEM_result)
    );


    reg [31:0] next_pc;

    always @ (posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            IF_pc <= 0;
            IF_ID <= 0;
            ID_EX <= 0;
            EX_MEM <= 0;
        end

        else begin

            IF_pc <= next_pc; 
            IF_ID <= IF_pc;
            ID_EX <= {ID_pc, ID_funct3, ID_field, ID_ALUOp, ID_RegSrc, ID_ALUSrc, ID_RegWrite, ID_MemRead, ID_MemWrite, ID_Branch, ID_Jump, ID_rs1_data, ID_rs2_data, ID_eximm, ID_rd};
            EX_MEM <= {EX_pc, EX_pc_eximm, EX_funct3, EX_RegSrc, EX_RegWrite, EX_MemRead, EX_ALU_result, EX_rd};
           
        end

    end

    // ***************************** COMBINATIONAL LOGIC ********************************

    // =============================== INSTRUCTION FETCH ================================

    Fetch INST9 (
        .Branch(EX_Branch),
        .branch_taken(EX_branch_taken),
        .Jump(EX_Jump),
        .ALUSrc(EX_ALUSrc),
        .pc(IF_pc),
        .eximm(EX_eximm),
        .rs1_data(EX_rs1_data),
        .next_pc(next_pc)
    );
            

    // =============================== REGFILE WRITE BACK ===============================

    always @ (*) begin

        case (MEM_RegSrc) 

            0: MEM_rd_write_data = MEM_ALU_result;
            1: MEM_rd_write_data = MEM_DMEM_result;
            2: MEM_rd_write_data = MEM_pc_eximm;
            3: MEM_rd_write_data = MEM_pc+4;

        endcase

    end

endmodule