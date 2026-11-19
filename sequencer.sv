`timescale 1ns / 1ps

module sequencer(
    input clk,
    input rst,
    input ack,
    output [15:0] data
    );
    
reg strb;
reg state;
reg [7:0] data_in;

assign data = {strb, 7'b0, data_in};

localparam OUTPUT_VALUE = 0;
localparam WAIT_ACK     = 1;

class randValues;
    rand int data_in;
    constraint c {
        data_in dist {
            [0:100]  := 1,
            [150:255]:= 1
        };
    };
endclass

randValues r;

initial begin
    r = new();
    strb = 0;
    state = OUTPUT_VALUE;
end

always@(posedge clk)
    if(rst == 0) begin
    
        case(state)
            OUTPUT_VALUE: 
                begin
                    r.randomize();
                    data_in = r.data_in;
                    strb = 1;
                    state = WAIT_ACK;
                end
            WAIT_ACK:
                if(ack) begin
                    strb  = 0;
                    state = OUTPUT_VALUE;
                end
        endcase
    end
    
endmodule
