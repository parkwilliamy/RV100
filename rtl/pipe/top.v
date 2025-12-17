`timescale 1ns/1ps

module top (
    input clk, sw0, sw1, RX,
    output TX,
    output [1:0] led
);

    wire rst_n_cpu, rst_n_mem, rst_clk;

    wire [3:0] wea, web;
    wire [15:0] addra, addrb; // 32 KB for IMEM and DMEM total
    wire [15:0] addra_cpu, addrb_cpu;
    wire [15:0] addra_mem, addrb_mem;
    wire [31:0] doa, dob; // Port A is IMEM, Port B is DMEM
    wire [31:0] dia, dib;
    
    reg [15:0] row_a_result, row_b_result;
    wire [15:0] row_a, row_b;
    wire [1:0] setting;

    localparam CPU_ON = 2'b01, MEM_ON = 2'b10;
    
    assign setting = {sw1, sw0}; // 00 and 11 are RESET states, 01 is when CPU is exclusively on, 10 is when MemAccess is exclusively on
    assign led = setting;

    assign row_a = row_a_result;
    assign row_b = row_b_result;

    wire clk_out1;
    
    clk_wiz_0 INST1 (
        
      // Clock out ports  
      .clk_out1(clk_out1),
      // Status and control signals               
      .reset(rst_clk), 
      .locked(),
     // Clock in ports
      .clk_in1(clk)
    );
    
    // byte addressable memory that uses the nearest word as an index
    blk_mem_gen_0 INST2 ( 
        .clka(clk_out1),
        .clkb(clk_out1),
        .wea(wea),
        .web(web),
        .addra(row_a[12:0]),
        .addrb(row_b[12:0]),
        .dina(dia),
        .dinb(dib),
        .douta(doa),
        .doutb(dob)
    );
    

    CPU INST3 (
        .clk(clk_out1),
        .rst_n(rst_n_cpu),
        .doa(doa),
        .dob(dob),
        .addra(addra_cpu),
        .addrb(addrb_cpu),
        .web(web),
        .dib(dib)
    );

    wire TX_enable, byte_done;
    wire [7:0] TX_data, RX_data;
    
    (* DONT_TOUCH = "yes" *) UART INST4 (
        .clk(clk_out1),
        .rst_n(rst_n_mem),
        .RX(RX),
        .TX_enable(TX_enable),
        .TX_data(TX_data),
        .TX(TX),
        .byte_done(byte_done),
        .RX_data(RX_data)
    );
    
    (* DONT_TOUCH = "yes" *) MemAccess INST5 (
        .clk(clk_out1),
        .rst_n(rst_n_mem),
        .byte_done(byte_done),
        .RX_data(RX_data),
        .dob(dob),
        .TX_enable(TX_enable),
        .addra(addra_mem),
        .addrb(addrb_mem),
        .wea(wea),
        .dia(dia),
        .TX_data(TX_data)
    );

    always @ (*) begin
        
        case (setting) 

            CPU_ON: begin

                rst_n_cpu = 1;
                rst_n_mem = 0;
                rst_clk = 0;
                row_a_result = addra_cpu >> 2;
                row_b_result = addrb_cpu >> 2;

            end

            MEM_ON: begin

                rst_n_cpu = 0;
                rst_n_mem = 1;
                rst_clk = 0;
                row_a_result = addra_mem >> 2;
                row_b_result = addrb_mem >> 2;

            end

            default: begin

                rst_n_cpu = 0;
                rst_n_mem = 0;
                rst_clk = 1;
                row_a_result = 0;
                row_b_result = 0;

            end

        endcase


    end


endmodule