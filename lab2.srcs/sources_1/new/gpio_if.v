`timescale 1ns / 1ps

module gpio_if (
    input  [15:0] gpio_o,
    output [15:0] gpio2_i,

    output        data_out,
    output        strb_out,
    output        ack_out,
    output        busy,
    output        done,

    input         data_in,
    input         strb_in,
    input         ack_in
);

    assign data_out = gpio_o[0];
    assign strb_out = gpio_o[1];
    assign ack_out  = gpio_o[2];
    assign busy     = gpio_o[3];
    assign done     = gpio_o[4];

    assign gpio2_i  = {13'b0, ack_in, strb_in, data_in};

endmodule
