`timescale 1ns / 1ps

class randValues;
    rand bit [7:0] data_in;
    constraint c {
        data_in dist {
            [25:70]   := 5,
            [150:200] := 1
        };
    }
endclass

module sequencer (
    input         clk,
    input         rst,
    input         ack_out,
    input  [31:0] seed,
    output reg    data_in = 1'b0,
    output reg    strb_in = 1'b0
);

    localparam LOAD_BYTE    = 2'd0;
    localparam SEND_BIT     = 2'd1;
    localparam WAIT_ACK     = 2'd2;
    localparam WAIT_ACK_LOW = 2'd3;

    reg [1:0] state;
    reg [7:0] value;
    reg [2:0] bit_idx;

    randValues r;

    initial begin
        r = new();
        state = LOAD_BYTE;
        @(negedge rst);
        r.srandom(seed);
    end

    always @(posedge clk) begin
        if (rst) begin
            strb_in <= 1'b0;
            state   <= LOAD_BYTE;
        end else begin
            case (state)
                LOAD_BYTE: begin
                    if (!r.randomize())
                        $error("sequencer: randomize() failed");
                    value   <= r.data_in;
                    bit_idx <= 3'd0;
                    state   <= SEND_BIT;
                end
                SEND_BIT: begin
                    data_in <= value[bit_idx];
                    strb_in <= 1'b1;
                    state   <= WAIT_ACK;
                end
                WAIT_ACK:
                    if (ack_out) begin
                        strb_in <= 1'b0;
                        state   <= WAIT_ACK_LOW;
                    end
                WAIT_ACK_LOW:
                    if (!ack_out) begin
                        bit_idx <= bit_idx + 3'd1;
                        state   <= (bit_idx == 3'd7) ? LOAD_BYTE : SEND_BIT;
                    end
            endcase
        end
    end

endmodule
