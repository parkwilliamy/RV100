`timescale 1ns/1ps

module UART (
    input clk, rst_n, RX, tx_ready,
    input [7:0] TX_data,
    output TX, byte_done,
    output reg [7:0] DATA_RX
);

    // This module assumes a baud rate of 1Mb/s
    localparam MAX_COUNT = 28,
               IDLE = 3'b000, 
               START_RX = 3'b001, 
               START_TX = 3'b010, 
               DATA_RX = 3'b011,
               DATA_TX = 3'b100,
               STOP_RX = 3'b101,
               STOP_TX = 3'b110;

    reg [2:0] current_state, next_state;
    reg [4:0] baud_count;
    reg [2:0] data_idx;
    reg baud_tick;
    reg [7:0] data_buffer;

    reg [1:0] RX_buffer;
    wire RX_negedge;
    assign RX_negedge = RX_buffer[1] && !RX_buffer[0];

    always @ (posedge clk) begin

        if (!rst_n) begin

            current_state <= 0;
            baud_count <= 0;
            data_idx <= 0;
            baud_tick <= 0;
            data_buffer <= 0;
            RX_buffer <= 0;
            DATA_RX <= 0;

        end

        else begin

            current_state <= next_state;
            RX_buffer <= {RX_buffer[0], RX};
            baud_count <= baud_count+1;

            if (current_state == IDLE) begin

                if (RX_negedge) baud_count <= 13; // START_RX baud counter from halfway for half baud tick

            end

            else if (current_state == START_RX) begin

                if (baud_tick) data_idx <= 0; // reset DATA_RX counter to 0 before transition to DATA_RX

            end

            else if (current_state == DATA_RX) begin

                if (baud_tick) begin

                    data_idx <= data_idx+1;
                    data_buffer <= {data_buffer[6:0], RX};

                end

            end

            else if (current_state == STOP_RX) begin

                if (baud_tick) DATA_RX <= data_buffer;

            end

            if (baud_count == MAX_COUNT-1) begin

                baud_tick <= 1;
                baud_count <= 0;

            end

            else baud_tick <= 0;

        end


    end

    // State Transition Logic

    always @ (*) begin

        case (current_state) 

            IDLE: begin

                if (RX_negedge) next_state = START_RX;
                else if (tx_ready) next_state = START_TX;
                else next_state = IDLE;

            end

            START_RX: begin

                if (baud_tick) begin
                    
                    if (!RX) next_state = DATA_RX;
                    else next_state = IDLE;

                end

                else next_state = START_RX;
                    
            end

            START_TX: begin


            end

            DATA_RX: begin

                if (data_idx == 7) next_state = STOP_RX;
                else next_state = DATA_RX;

            end

            DATA_TX: begin


            end

            STOP_RX: begin

                if (baud_tick && RX) next_state = IDLE;
                else next_state = STOP_RX;

            end

            STOP_TX: begin



            end

        endcase

    end



endmodule