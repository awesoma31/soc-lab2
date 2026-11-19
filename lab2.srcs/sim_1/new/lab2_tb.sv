`timescale 1ns / 1ps

module lab2_tb;

    localparam CLK_PERIOD = 10;
    localparam N          = 10;

    reg         clk_100MHz  = 1'b0;
    reg         reset_rtl_0 = 1'b1;
    reg  [31:0] seed;

    wire data_in, strb_in, ack_out;
    wire data_out, strb_out, ack_in;
    wire busy, done;

    always #(CLK_PERIOD / 2) clk_100MHz = ~clk_100MHz;

    initial begin
        if (!$value$plusargs("seed=%d", seed))
            seed = $urandom;
        reset_rtl_0 = 1'b1;
        #(20 * CLK_PERIOD);
        reset_rtl_0 = 1'b0;
    end

    sequencer seq (
        .clk     (clk_100MHz),
        .rst     (reset_rtl_0),
        .ack_out (ack_out),
        .seed    (seed),
        .data_in (data_in),
        .strb_in (strb_in)
    );

    design_1_wrapper dut (
        .clk_100MHz  (clk_100MHz),
        .reset_rtl_0 (reset_rtl_0),
        .data_in     (data_in),
        .strb_in     (strb_in),
        .ack_in      (ack_in),
        .data_out    (data_out),
        .strb_out    (strb_out),
        .ack_out     (ack_out),
        .busy        (busy),
        .done        (done)
    );

    monitor #(
        .N          (N),
        .C_BITS     (20),
        .CLK_PERIOD (CLK_PERIOD)
    ) mon (
        .clk      (clk_100MHz),
        .rst      (reset_rtl_0),
        .data_in  (data_in),
        .strb_in  (strb_in),
        .ack_out  (ack_out),
        .data_out (data_out),
        .strb_out (strb_out),
        .busy     (busy),
        .done     (done),
        .seed     (seed),
        .ack_in   (ack_in)
    );

endmodule
