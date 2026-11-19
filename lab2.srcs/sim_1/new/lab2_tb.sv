`timescale 1ns / 1ps

module lab2_tb;

    localparam CLK_PERIOD = 10;
    localparam N          = 10;
    localparam C_BITS     = 20;

    localparam integer IN_ROW  = 1, IN_COL  = 3, IN_BIT  = 3;
    localparam integer OUT_ROW = 2, OUT_COL = 7, OUT_BIT = 5;
    localparam integer IN_FLIP  = (IN_ROW * N + IN_COL) * 8 + IN_BIT;
    localparam integer OUT_FLIP = (OUT_ROW * N + OUT_COL) * C_BITS + OUT_BIT;

    reg         clk_100MHz  = 1'b0;
    reg         reset_rtl_0 = 1'b1;
    reg  [31:0] seed;
    string      inject = "";
    bit         inject_in = 0, inject_out = 0;

    wire seq_data_in, dut_data_in, strb_in, ack_out;
    wire dut_data_out, mon_data_out, strb_out, ack_in;

    integer in_bits = 0, out_bits = 0;
    reg     strb_in_d = 1'b0, strb_out_d = 1'b0;

    always #(CLK_PERIOD / 2) clk_100MHz = ~clk_100MHz;

    always @(posedge clk_100MHz) begin
        strb_in_d  <= strb_in;
        strb_out_d <= strb_out;
        if (strb_in_d  === 1'b1 && strb_in  === 1'b0) in_bits++;
        if (strb_out_d === 1'b1 && strb_out === 1'b0) out_bits++;
    end

    assign dut_data_in  = seq_data_in  ^ (inject_in  && in_bits  == IN_FLIP);
    assign mon_data_out = dut_data_out ^ (inject_out && out_bits == OUT_FLIP);

    initial begin
        if (!$value$plusargs("seed=%d", seed))
            seed = $urandom;
        if ($value$plusargs("inject=%s", inject)) begin
            inject_in  = (inject == "in");
            inject_out = (inject == "out");
        end
        reset_rtl_0 = 1'b1;
        #(20 * CLK_PERIOD);
        reset_rtl_0 = 1'b0;
        #1;
        if (inject_in)
            mon.log(0, $sformatf("INJECT: test 1, bit %0d of A[%0d][%0d] is flipped between the sequencer and the DUT",
                                 IN_BIT, IN_ROW, IN_COL));
        else if (inject_out)
            mon.log(0, $sformatf("INJECT: test 1, bit %0d of C[%0d][%0d] is flipped between the DUT and the monitor",
                                 OUT_BIT, OUT_ROW, OUT_COL));
        else if (inject != "")
            mon.log(0, $sformatf("INJECT: unknown mode \"%s\", use inject=in or inject=out", inject));
    end

    sequencer seq (
        .clk     (clk_100MHz),
        .rst     (reset_rtl_0),
        .ack_out (ack_out),
        .seed    (seed),
        .data_in (seq_data_in),
        .strb_in (strb_in)
    );

    design_1_wrapper dut (
        .clk_100MHz  (clk_100MHz),
        .reset_rtl_0 (reset_rtl_0),
        .data_in     (dut_data_in),
        .strb_in     (strb_in),
        .ack_in      (ack_in),
        .data_out    (dut_data_out),
        .strb_out    (strb_out),
        .ack_out     (ack_out)
    );

    monitor #(
        .N          (N),
        .C_BITS     (C_BITS),
        .CLK_PERIOD (CLK_PERIOD)
    ) mon (
        .clk      (clk_100MHz),
        .rst      (reset_rtl_0),
        .data_in  (seq_data_in),
        .strb_in  (strb_in),
        .ack_out  (ack_out),
        .data_out (mon_data_out),
        .strb_out (strb_out),
        .seed     (seed),
        .ack_in   (ack_in)
    );

endmodule
