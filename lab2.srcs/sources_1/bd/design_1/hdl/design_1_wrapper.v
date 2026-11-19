//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Thu Nov 19 00:09:27 2026
//Host        : awesoma-win running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (ack_in,
    ack_out,
    busy,
    clk_100MHz,
    data_in,
    data_out,
    done,
    reset_rtl_0,
    strb_in,
    strb_out);
  input ack_in;
  output ack_out;
  output busy;
  input clk_100MHz;
  input data_in;
  output data_out;
  output done;
  input reset_rtl_0;
  input strb_in;
  output strb_out;

  wire ack_in;
  wire ack_out;
  wire busy;
  wire clk_100MHz;
  wire data_in;
  wire data_out;
  wire done;
  wire reset_rtl_0;
  wire strb_in;
  wire strb_out;

  design_1 design_1_i
       (.ack_in(ack_in),
        .ack_out(ack_out),
        .busy(busy),
        .clk_100MHz(clk_100MHz),
        .data_in(data_in),
        .data_out(data_out),
        .done(done),
        .reset_rtl_0(reset_rtl_0),
        .strb_in(strb_in),
        .strb_out(strb_out));
endmodule
