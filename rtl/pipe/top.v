`timescale 1ns/1ps

module top (
    input rst_n, clk,
    output reg [27:0] clk_cycles, // assuming peak clock speed around 75MHz and longest program length around 3s
    output reg [12:0] retired_instructions, // assuming max instructions in a program around 8000
    output reg [12:0] predictions_made, // total number of branch instructions
    output reg [12:0] correct_predictions, // total number of correct predictions
    output reg [12:0] invalid_clk_cycles // clock cycles elapsed where an invalid instruction is in the pipeline
);


    // ************************************* MEMORY ************************************* 

    wire [3:0] wea, web;
    wire [31:0] addra, addrb, doa, dob; // Port A is IMEM, Port B is DMEM
    wire [31:0] dia, dib;

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

    // IF

    reg [31:0] IF_pc;
    wire [31:0] next_pc;

    // ID

    reg [31:0] ID_pc, ID_pc_4;
    reg [7:0] ID_BHTaddr;
    reg [1:0] ID_branch_prediction;
    reg ID_BTBhit;
    reg [2:0] ID_ValidReg;
    reg [1:0] ID_ALUOp, ID_RegSrc; 
    reg ID_ALUSrc, ID_RegWrite, ID_MemRead, ID_MemWrite, ID_Valid; 
    reg [3:0] ID_field;
    reg [31:0] ID_imm, ID_rs1_data, ID_rs2_data;

    // EX
    
    reg [3:0] EX_field;
    reg [2:0] EX_ValidReg, EX_funct3;
    reg [1:0] EX_ALUOp, EX_RegSrc, EX_branch_prediction;
    reg EX_ALUSrc, EX_RegWrite, EX_MemRead, EX_MemWrite, EX_Branch, EX_Jump;
    reg [31:0] EX_pc_4, EX_rs1_data, EX_rs2_data, EX_imm, EX_pc_imm;
    reg [4:0] EX_rs1, EX_rs2, EX_rd;
    reg [7:0] EX_BHTaddr;

    // MEM

    reg [31:0] MEM_pc_4;
    reg [2:0] MEM_funct3, MEM_ValidReg;
    reg [1:0] MEM_RegSrc; 
    reg MEM_MemRead, MEM_MemWrite, MEM_RegWrite;
    reg [31:0] MEM_pc_imm, MEM_ALU_result, MEM_rs2_data, MEM_rs2_fwd_data, MEM_rs2_data_final;
    reg [4:0] MEM_rs2, MEM_rd;

    // WB

    reg [31:0] WB_pc_imm, WB_pc_4, WB_ALU_result;
    reg [2:0] WB_funct3, WB_ValidReg;
    reg [1:0] WB_RegSrc; 
    reg WB_MemRead;
    reg WB_RegWrite;
    reg [4:0] WB_rd;
    reg [31:0] WB_rd_write_data;



    // *********************************** MODULES **************************************
               
    // =============================== INSTRUCTION FETCH ================================

    wire [31:0] IF_pc_4, IF_pc_imm, ID_pc_imm;
    wire IF_Branch, IF_Jump, ID_Branch, ID_Jump, BTBwrite, IF_BTBhit;

    reg [1:0] BHT [255:0];
    reg [7:0] gh;

    wire [7:0] IF_BHTaddr;
    assign IF_BHTaddr = IF_pc[9:2] ^ gh;

    wire [1:0] IF_branch_prediction;
    assign IF_branch_prediction = BHT[IF_BHTaddr];

    BTB INST2 (
        .clk(clk), 
        .rst_n(rst_n),
        .write(BTBwrite),
        .ID_Branch(ID_Branch),
        .ID_Jump(ID_Jump),
        .IF_pc(IF_pc),
        .ID_pc(ID_pc),
        .pc_imm_in(ID_pc_imm),
        .pc_imm_out(IF_pc_imm),
        .hit(IF_BTBhit),
        .IF_Branch(IF_Branch),
        .IF_Jump(IF_Jump)
    );
    
    
    // =============================== INSTRUCTION DECODE ===============================

    wire [31:0] ID_instruction;

    wire [6:0] ID_opcode;
    wire [11:7] ID_rd;
    wire [14:12] ID_funct3;
    wire [19:15] ID_rs1;
    wire [24:20] ID_rs2;
    wire [31:25] ID_funct7;
    wire ID_Stall, ID_Flush;
    reg ID_PostFlush;

    assign ID_instruction = ID_PostFlush ? 0 : doa;
    assign ID_opcode = ID_instruction[6:0];
    assign ID_rd = ID_instruction[11:7];
    assign ID_funct3 = ID_instruction[14:12];
    assign ID_rs1 = ID_instruction[19:15];
    assign ID_rs2 = ID_instruction[24:20];
    assign ID_funct7 = ID_instruction[31:25];

    assign addra = ID_Stall ? ID_pc : IF_pc;

    ControlUnit INST3 (
        .opcode(ID_opcode), 
        .ValidReg(ID_ValidReg),
        .ALUOp(ID_ALUOp), 
        .RegSrc(ID_RegSrc), 
        .ALUSrc(ID_ALUSrc), 
        .RegWrite(ID_RegWrite), 
        .MemRead(ID_MemRead), 
        .MemWrite(ID_MemWrite), 
        .Branch(ID_Branch),
        .Jump(ID_Jump),
        .Valid(ID_Valid)
    );

    RegFile INST4 (
        .clk(clk), 
        .rst_n(rst_n),
        .RegWrite(WB_RegWrite), 
        .rs1(ID_rs1), 
        .rs2(ID_rs2), 
        .rd(WB_rd), 
        .rd_write_data(WB_rd_write_data), 
        .rs1_data(ID_rs1_data), 
        .rs2_data(ID_rs2_data)
    );

    ImmGen INST5 (
        .instruction(ID_instruction), 
        .imm(ID_imm)
    );

    ALUControl INST6 (
        .funct7(ID_funct7), 
        .funct3(ID_funct3), 
        .ALUOp(ID_ALUOp), 
        .regbit(ID_opcode[5]), 
        .field(ID_field)
    );

    assign ID_pc_imm = ID_pc + ID_imm;
    assign BTBwrite = (ID_Jump || ID_Branch) ? 1 : 0;
    

    // ==================================== EXECUTE =====================================

    wire EX_zero, EX_sign, EX_overflow, EX_carry;

    wire [31:0] EX_op1, EX_op2, EX_rs1_fwd_data, EX_rs2_fwd_data, EX_rs1_data_final, EX_rs2_data_final;

    wire EX_Flush;
 
    assign EX_op1 = (EX_ALUOp == 1 && EX_ALUSrc == 1 && EX_RegSrc == 0 && EX_RegWrite == 1 && EX_ValidReg == 3'b001) ? 0 : EX_rs1_data_final;
    assign EX_op2 = EX_ALUSrc ? EX_imm : EX_rs2_data_final;

    wire [31:0] EX_ALU_result;

    ALU INST7 (
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
    wire [1:0] EX_prediction_status;

    BRU INST8 (
        .EX_branch_prediction(EX_branch_prediction),
        .EX_Branch(EX_Branch), 
        .zero(EX_zero), 
        .sign(EX_sign), 
        .overflow(EX_overflow), 
        .carry(EX_carry),
        .funct3(EX_funct3),
        .branch_taken(EX_branch_taken),
        .prediction_status(EX_prediction_status)
    );


    // ================================== MEMORY WRITE ==================================

    assign addrb = MEM_ALU_result;

    Store INST9 (
        .MemWrite(MEM_MemWrite),
        .addrb(MEM_ALU_result),
        .rs2_data(MEM_rs2_data_final),
        .funct3(MEM_funct3),
        .web(web),
        .dib(dib)
    );


    // =============================== REGFILE WRITE BACK ===============================

    WriteBack INST10 (
        .ALU_result(WB_ALU_result), 
        .pc_imm(WB_pc_imm), 
        .pc_4(WB_pc_4),
        .funct3(WB_funct3),
        .RegSrc(WB_RegSrc),
        .DMEM_word(dob),
        .rd_write_data(WB_rd_write_data)
    );

    Fetch INST11 (
        .IF_branch_prediction(IF_branch_prediction),
        .ID_branch_prediction(ID_branch_prediction),
        .prediction_status(EX_prediction_status),
        .IF_BTBhit(IF_BTBhit),
        .ID_BTBhit(ID_BTBhit),
        .IF_Branch(IF_Branch),
        .IF_Jump(IF_Jump),
        .ID_Branch(ID_Branch),
        .EX_Branch(EX_Branch),
        .ID_Jump(ID_Jump),
        .EX_Jump(EX_Jump),
        .ID_ALUSrc(ID_ALUSrc),
        .EX_ALUSrc(EX_ALUSrc),
        .IF_pc(IF_pc),
        .IF_pc_imm(IF_pc_imm),
        .EX_pc_4(EX_pc_4),
        .ID_pc_imm(ID_pc_imm),
        .EX_pc_imm(EX_pc_imm),
        .rs1_imm(EX_ALU_result),
        .IF_pc_4(IF_pc_4),
        .next_pc(next_pc),
        .ID_Flush(ID_Flush),
        .EX_Flush(EX_Flush)
    );


    // ================================== FORWARDING ====================================

    wire EX_rs1_fwd, EX_rs2_fwd;

    ForwardUnit INST12 (
        .MEM_ALU_result(MEM_ALU_result),
        .MEM_pc_4(MEM_pc_4),
        .MEM_pc_imm(MEM_pc_imm),
        .MEM_RegSrc(MEM_RegSrc),
        .WB_rd_write_data(WB_rd_write_data),
        .EX_rs1(EX_rs1), 
        .EX_rs2(EX_rs2), 
        .MEM_rs2(MEM_rs2),
        .MEM_rd(MEM_rd), 
        .WB_rd(WB_rd),
        .EX_ValidReg(EX_ValidReg), 
        .MEM_ValidReg(MEM_ValidReg), 
        .WB_ValidReg(WB_ValidReg),
        .MEM_MemRead(MEM_MemRead),
        .MEM_MemWrite(MEM_MemWrite),
        .WB_MemRead(WB_MemRead),
        .EX_rs1_fwd(EX_rs1_fwd), 
        .EX_rs2_fwd(EX_rs2_fwd),
        .MEM_rs2_fwd(MEM_rs2_fwd),
        .EX_rs1_fwd_data(EX_rs1_fwd_data),
        .EX_rs2_fwd_data(EX_rs2_fwd_data),
        .MEM_rs2_fwd_data(MEM_rs2_fwd_data)
    );

    assign EX_rs1_data_final = (EX_rs1_fwd) ? EX_rs1_fwd_data : EX_rs1_data;
    assign EX_rs2_data_final = (EX_rs2_fwd) ? EX_rs2_fwd_data : EX_rs2_data;
    assign MEM_rs2_data_final = (MEM_rs2_fwd) ? MEM_rs2_fwd_data : MEM_rs2_data;


    // =================================== STALLING =====================================

    StallUnit INST13 (
        .EX_MemRead(EX_MemRead),
        .ID_MemWrite(ID_MemWrite),
        .EX_rd(EX_rd),
        .ID_rs1(ID_rs1),
        .ID_rs2(ID_rs2),
        .ID_ValidReg(ID_ValidReg),
        .Stall(ID_Stall)
    );
    
    integer i;

    always @ (posedge clk) begin

        if (!rst_n) begin

            clk_cycles <= 0;
            retired_instructions <= 0;
            correct_predictions <= 0;
            predictions_made <= 0;

            ID_PostFlush <= 0;
            gh <= 0;
        
            // IF

            IF_pc <= 32'b0; 

            // ID

            ID_pc <= 32'b0;
            ID_pc_4 <= 32'b0;
            ID_BHTaddr <= 8'b0;
            ID_branch_prediction <= 2'b0;
            ID_BTBhit <= 1'b0;

            // EX

            EX_pc_4 <= 32'b0;
            EX_pc_imm <= 32'b0;
            EX_BHTaddr <= 8'b0;
            EX_funct3 <= 3'b000;
            EX_field <= 4'b0000;
            EX_ValidReg <= 3'b000;
            EX_ALUOp <= 2'b00;
            EX_RegSrc <= 2'b00;
            EX_ALUSrc <= 1'b0;
            EX_RegWrite <= 1'b0;
            EX_MemRead <= 1'b0;
            EX_MemWrite <= 1'b0;
            EX_Branch <= 1'b0;
            EX_branch_prediction <= 2'b0;
            EX_Jump <= 1'b0;
            EX_rs1_data <= 32'b0;
            EX_rs2_data <= 32'b0;
            EX_imm <= 32'b0;
            EX_rd <= 5'b0;
            EX_rs1 <= 5'b0;
            EX_rs2 <= 5'b0;

            // MEM

            MEM_pc_4 <= 0;
            MEM_pc_imm <= 0;
            MEM_funct3 <= 0;
            MEM_ValidReg <= 0;
            MEM_RegSrc <= 0;
            MEM_RegWrite <= 0;
            MEM_MemRead <= 0;
            MEM_MemWrite <= 0;
            MEM_ALU_result <= 0;
            MEM_rs2_data <= 0;
            MEM_rs2 <= 0;
            MEM_rd <= 0;

            // WB

            WB_pc_4 <= 0;
            WB_pc_imm <= 0;
            WB_funct3 <= 0;
            WB_ValidReg <= 0;
            WB_RegSrc <= 0;
            WB_MemRead <= 0;
            WB_RegWrite <= 0;
            WB_ALU_result <= 0;
            WB_rd <= 0;

            for (i = 0; i < 256; i = i+1) begin

                BHT[i] <= 2'b01;

            end

        end

        else begin

            ID_PostFlush <= 0;
            clk_cycles <= clk_cycles+1;

            if (EX_Branch) predictions_made <= predictions_made+1;

            if (!ID_Valid) invalid_clk_cycles <= invalid_clk_cycles+1;

            if (WB_ValidReg != 3'b000) retired_instructions <= retired_instructions+1;

            if (ID_Flush || EX_Flush) begin

                IF_pc <= next_pc;

                if (ID_Flush) begin

                    ID_pc <= 32'b0;
                    ID_pc_4 <= 32'b0;
                    ID_BHTaddr <= 8'b0;
                    ID_branch_prediction <= 2'b0;
                    ID_BTBhit <= 1'b0;
                    ID_PostFlush <= 1;

                end
                else begin

                    ID_pc <= ID_pc;
                    ID_pc_4 <= ID_pc_4;
                    ID_BHTaddr <= ID_BHTaddr;
                    ID_branch_prediction <= ID_branch_prediction;
                    ID_BTBhit <= ID_BTBhit;

                end
                if (EX_Flush) begin
                    
                    EX_pc_4 <= 32'b0;
                    EX_pc_imm <= 32'b0;
                    EX_BHTaddr <= 8'b0;
                    EX_funct3 <= 3'b000;
                    EX_field <= 4'b0000;
                    EX_ValidReg <= 3'b000;
                    EX_ALUOp <= 2'b00;
                    EX_RegSrc <= 2'b00;
                    EX_ALUSrc <= 1'b0;
                    EX_RegWrite <= 1'b0;
                    EX_MemRead <= 1'b0;
                    EX_MemWrite <= 1'b0;
                    EX_Branch <= 1'b0;
                    EX_branch_prediction <= 2'b0;
                    EX_Jump <= 1'b0;
                    EX_rs1_data <= 32'b0;
                    EX_rs2_data <= 32'b0;
                    EX_imm <= 32'b0;
                    EX_rd <= 5'b0;
                    EX_rs1 <= 5'b0;
                    EX_rs2 <= 5'b0;

                end
                else begin

                    EX_pc_4 <= ID_pc_4;
                    EX_pc_imm <= ID_pc_imm;
                    EX_BHTaddr <= ID_BHTaddr;
                    EX_funct3 <= ID_funct3;
                    EX_field <= ID_field;
                    EX_ValidReg <= ID_ValidReg;
                    EX_ALUOp <= ID_ALUOp;
                    EX_RegSrc <= ID_RegSrc;
                    EX_ALUSrc <= ID_ALUSrc;
                    EX_RegWrite <= ID_RegWrite;
                    EX_MemRead <= ID_MemRead;
                    EX_MemWrite <= ID_MemWrite;
                    EX_Branch <= ID_Branch;
                    EX_branch_prediction <= ID_branch_prediction;
                    EX_Jump <= ID_Jump;
                    EX_rs1_data <= ID_rs1_data;
                    EX_rs2_data <= ID_rs2_data;
                    EX_imm <= ID_imm;
                    EX_rd <= ID_rd;
                    EX_rs1 <= ID_rs1;
                    EX_rs2 <= ID_rs2;

                end

                // MEM

                MEM_pc_4 <= EX_pc_4;
                MEM_pc_imm <= EX_pc_imm;
                MEM_funct3 <= EX_funct3;
                MEM_ValidReg <= EX_ValidReg;
                MEM_RegSrc <= EX_RegSrc;
                MEM_RegWrite <= EX_RegWrite;
                MEM_MemRead <= EX_MemRead;
                MEM_MemWrite <= EX_MemWrite;
                MEM_ALU_result <= EX_ALU_result;
                MEM_rs2_data <= EX_rs2_data_final;
                MEM_rs2 <= EX_rs2;
                MEM_rd <= EX_rd;

                // WB
                
                WB_pc_4 <= MEM_pc_4;
                WB_pc_imm <= MEM_pc_imm;
                WB_funct3 <= MEM_funct3;
                WB_ValidReg <= MEM_ValidReg;
                WB_RegSrc <= MEM_RegSrc;
                WB_MemRead <= MEM_MemRead;
                WB_RegWrite <= MEM_RegWrite;
                WB_ALU_result <= MEM_ALU_result;
                WB_rd <= MEM_rd;

            end
            
            else if (ID_Stall) begin
                
                // IF

                IF_pc <= IF_pc; 

                // ID

                ID_pc <= ID_pc;
                ID_pc_4 <= ID_pc_4;
                ID_BHTaddr <= ID_BHTaddr;
                ID_branch_prediction <= ID_branch_prediction;
                ID_BTBhit <= ID_BTBhit;

                // EX

                EX_pc_4 <= EX_pc_4;
                EX_pc_imm <= EX_pc_imm;
                EX_BHTaddr <= EX_BHTaddr;
                EX_funct3 <= 3'b000;
                EX_field <= 4'b0000;
                EX_ValidReg <= 3'b000;
                EX_ALUOp <= 2'b00;
                EX_RegSrc <= 2'b00;
                EX_ALUSrc <= 1'b0;
                EX_RegWrite <= 1'b0;
                EX_MemRead <= 1'b0;
                EX_MemWrite <= 1'b0;
                EX_Branch <= 1'b0;
                EX_branch_prediction <= 2'b0;
                EX_Jump <= 1'b0;
                EX_rs1_data <= EX_rs1_data;
                EX_rs2_data <= EX_rs2_data;
                EX_imm <= EX_imm;
                EX_rd <= EX_rd;
                EX_rs1 <= EX_rs1;
                EX_rs2 <= EX_rs2;

                // MEM

                MEM_pc_4 <= EX_pc_4;
                MEM_pc_imm <= EX_pc_imm;
                MEM_funct3 <= EX_funct3;
                MEM_ValidReg <= EX_ValidReg;
                MEM_RegSrc <= EX_RegSrc;
                MEM_RegWrite <= EX_RegWrite;
                MEM_MemRead <= EX_MemRead;
                MEM_MemWrite <= EX_MemWrite;
                MEM_ALU_result <= EX_ALU_result;
                MEM_rs2_data <= EX_rs2_data_final;
                MEM_rs2 <= EX_rs2;
                MEM_rd <= EX_rd;

                // WB
                
                WB_pc_4 <= MEM_pc_4;
                WB_pc_imm <= MEM_pc_imm;
                WB_funct3 <= MEM_funct3;
                WB_ValidReg <= MEM_ValidReg;
                WB_RegSrc <= MEM_RegSrc;
                WB_MemRead <= MEM_MemRead;
                WB_RegWrite <= MEM_RegWrite;
                WB_ALU_result <= MEM_ALU_result;
                WB_rd <= MEM_rd;

            end else begin
            
                // IF

                IF_pc <= next_pc; 

                // ID

                ID_pc <= IF_pc;
                ID_pc_4 <= IF_pc_4;
                ID_BHTaddr <= IF_BHTaddr;
                ID_branch_prediction <= IF_branch_prediction;
                ID_BTBhit <= IF_BTBhit;

                // EX

                EX_pc_4 <= ID_pc_4;
                EX_pc_imm <= ID_pc_imm;
                EX_BHTaddr <= ID_BHTaddr;
                EX_funct3 <= ID_funct3;
                EX_field <= ID_field;
                EX_ValidReg <= ID_ValidReg;
                EX_ALUOp <= ID_ALUOp;
                EX_RegSrc <= ID_RegSrc;
                EX_ALUSrc <= ID_ALUSrc;
                EX_RegWrite <= ID_RegWrite;
                EX_MemRead <= ID_MemRead;
                EX_MemWrite <= ID_MemWrite;
                EX_Branch <= ID_Branch;
                EX_branch_prediction <= ID_branch_prediction;
                EX_Jump <= ID_Jump;
                EX_rs1_data <= ID_rs1_data;
                EX_rs2_data <= ID_rs2_data;
                EX_imm <= ID_imm;
                EX_rd <= ID_rd;
                EX_rs1 <= ID_rs1;
                EX_rs2 <= ID_rs2;

                // MEM

                MEM_pc_4 <= EX_pc_4;
                MEM_pc_imm <= EX_pc_imm;
                MEM_funct3 <= EX_funct3;
                MEM_ValidReg <= EX_ValidReg;
                MEM_RegSrc <= EX_RegSrc;
                MEM_RegWrite <= EX_RegWrite;
                MEM_MemRead <= EX_MemRead;
                MEM_MemWrite <= EX_MemWrite;
                MEM_ALU_result <= EX_ALU_result;
                MEM_rs2_data <= EX_rs2_data_final;
                MEM_rs2 <= EX_rs2;
                MEM_rd <= EX_rd;

                // WB

                WB_pc_4 <= MEM_pc_4;
                WB_pc_imm <= MEM_pc_imm;
                WB_funct3 <= MEM_funct3;
                WB_ValidReg <= MEM_ValidReg;
                WB_RegSrc <= MEM_RegSrc;
                WB_MemRead <= MEM_MemRead;
                WB_RegWrite <= MEM_RegWrite;
                WB_ALU_result <= MEM_ALU_result;
                WB_rd <= MEM_rd;

            end

            if (EX_Branch) begin

                gh <= {gh[6:0], EX_branch_taken};

                case (EX_prediction_status)

                    0: begin
                        
                        BHT[EX_BHTaddr] <= BHT[EX_BHTaddr]+1;

                    end
                    1: begin
                        
                        BHT[EX_BHTaddr] <= BHT[EX_BHTaddr]-1;

                    end
                    2: begin
                        
                        if (BHT[EX_BHTaddr] > 0)  BHT[EX_BHTaddr] <= BHT[EX_BHTaddr]-1;
                        correct_predictions <= correct_predictions+1;

                    end
                    3: begin
                        
                        if (BHT[EX_BHTaddr] < 3 && EX_branch_prediction > 1)  BHT[EX_BHTaddr] <= BHT[EX_BHTaddr]+1;
                        correct_predictions <= correct_predictions+1;

                    end

                endcase

            end

        end

    end

   

        

endmodule