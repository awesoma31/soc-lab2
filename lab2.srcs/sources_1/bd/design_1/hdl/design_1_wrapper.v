//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Thu Nov 19 13:11:03 2026
//Host        : awesoma-win running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (ack_in,
    ack_out,
    clk_100MHz,
    data_in,
    data_out,
    reset_rtl_0,
    strb_in,
    strb_out);
  input ack_in;
  output ack_out;
  input clk_100MHz;
  input data_in;
  output data_out;
  input reset_rtl_0;
  input strb_in;
  output strb_out;

  wire ack_in;
  wire ack_out;
  wire clk_100MHz;
  wire data_in;
  wire data_out;
  wire reset_rtl_0;
  wire strb_in;
  wire strb_out;

  design_1 design_1_i
       (.ack_in(ack_in),
        .ack_out(ack_out),
        .clk_100MHz(clk_100MHz),
        .data_in(data_in),
        .data_out(data_out),
        .reset_rtl_0(reset_rtl_0),
        .strb_in(strb_in),
        .strb_out(strb_out));
endmodule
