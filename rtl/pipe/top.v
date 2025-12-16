`timescale 1ns/1ps

module top (
    input rst_n, clk, RX,
    output TX
);

    wire [3:0] wea, web;
    wire [15:0] addra, addrb; // 32 KB for IMEM and DMEM total
    wire [31:0] doa, dob; // Port A is IMEM, Port B is DMEM
    wire [31:0] dia, dib;

    // byte addressable memory that uses the nearest word as an index
    blk_mem_gen_0 INST1 ( 
        .clka(clk),
        .clkb(clk),
        .wea(wea),
        .web(web),
        .addra(addra>>2),
        .addrb(addrb>>2),
        .dina(dia),
        .dinb(dib),
        .douta(doa),
        .doutb(dob)
    );

    CPU INST2 (
        .clk(clk),
        .rst_n(rst_n),
        .addra(addra),
        .dob(dob),
        .addrb(addrb),
        .web(web),
        .dib(dib)
    );

    wire TX_enable, byte_done;
    wire [7:0] TX_data, RX_data;

    UART INST3 (
        .clk(clk),
        .rst_n(rst_n),
        .RX(RX),
        .TX_enable(TX_enable),
        .TX_data(TX_data),
        .TX(TX),
        .byte_done(byte_done),
        .RX_data(RX_data)
    );

    MemAccess INST4 (
        .clk(clk),
        .rst_n(rst_n),
        .byte_done(byte_done),
        .RX_data(RX_data),
        .dob(dob),
        .TX_enable(TX_enable),
        .addra(addra),
        .addrb(addrb),
        .wea(wea),
        .dia(dia),
        .TX_data(TX_data)
    );


endmodule