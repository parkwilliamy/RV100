`timescale 1ns/1ps

module MemAccess (
    input clk, rst_n, byte_done,
    input [7:0] RX_data,
    input [31:0] dob,
    output reg tx_ready,
    output reg [12:0] addra, addrb
    output reg [3:0] wea,
    output reg [31:0] dia,
    output reg [7:0] TX_data
);

    localparam ADDR_WIDTH = 13;
    localparam IDLE = 2'b00, WRITE = 2'b01, READ_1 = 2'b10, READ_2 = 2'b11;
    reg [1:0] current_state, next_state;

    reg [55:0] write_frame;
    reg [31:0] read_frame;
    reg [2:0] msgidx;
    reg [12:0] ADDR_LOW, ADDR_HIGH, addr_idx;

    integer i;

    assign addrb = ADDR_LOW+addr_idx;

    always @ (posedge clk) begin

        if (!rst_n) begin

            current_state <= IDLE;

            for (i=0; i < 8; i = i+1) begin

                write_frame[i] <= 0;

            end

            for (i=0; i < 4; i = i+1) begin

                read_frame[i] <= 0;

            end

            msgidx <= 0;
            addr_idx <= 0;
            tx_ready <= 0;
            TX_data <= 0;

        end

        else begin

            current_state <= next_state;

            if (current_state == IDLE) begin
                
                msgidx <= 0;
                addr_idx <= 0;
                tx_ready <= 0;

            end

            else if (current_state == WRITE) begin

                if (msgidx == 6) begin

                    addra <= write_frame[ADDR_WIDTH-1:0];
                    wea <= write_frame[19:16];
                    dia <= write_frame[55:24];

                end

                else msgidx <= msgidx+1;

                write_frame <= {RX_data, write_frame[55:8]};

            end

            else if (current_state == READ_1) begin

                if (msgidx == 3) begin

                    ADDR_LOW <= read_frame[ADDR_WIDTH-1:0];
                    ADDR_HIGH <= read_frame[ADDR_WIDTH-1+16:16];
                    tx_ready <= 1;

                end

                else msgidx <= msgidx+1;

                read_frame[msgidx] <= {RX_data, read_frame[31:8]};

            end

            else if (current_state == READ_2) begin

                if (byte_done) begin // state only advances once 4 bytes of a word are transmitted to pc

                    addr_idx <= addr_idx+1;
                    addrb <= ADDR_LOW+addr_idx;
                    TX_data <= dob[7+8*addr_idx -: 8];

                end

                
                


            end

        end


    end

    // STATE TRANSITION LOGIC

    always @ (*) begin

        case(current_state) 

            IDLE: begin

                if (RX_data == 8'h0F) next_state = WRITE;
                else if (RX_data == 8'hFF) next_state = READ_1;
                else next_state = IDLE;

            end

            WRITE: begin

                if (msgidx == 6) next_state = IDLE;
                else next_state = WRITE;

            end

            READ_1: begin

                if (msgidx == 3) next_state = READ_2;
                else next_state = READ_1;

            end

            READ_2: begin

                if (ADDR_LOW+addr_idx == ADDR_HIGH-4) next_state = IDLE;
                else next_state = READ_2;

            end

        endcase

    end



endmodule