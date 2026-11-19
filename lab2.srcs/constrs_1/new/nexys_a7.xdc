## Nexys A7-100T (xc7a100tcsg324-1) — lab2
## Pins taken from Digilent Nexys-A7-100T-Master.xdc
## Port names match design_1_wrapper (clk_100MHz, reset_rtl_0, data_in, strb_in, ack_in, data_out, strb_out, ack_out, busy, done)

## Clock 100 MHz
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { clk_100MHz }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk_100MHz }]

## Reset, active HIGH -> BTNC (center button, 1 while pressed)
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports { reset_rtl_0 }]
## If you switch reset to ACTIVE LOW, use CPU_RESETN instead (0 while pressed):
#set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { reset_rtl_0 }]

## LEDs: serial outputs of the DUT (variant 3)
## LD0
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { data_out }]
## LD1
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports { strb_out }]
## LD2
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports { ack_out }]
## LD3
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { busy }]
## LD4
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { done }]

## Switches stand in for the sequencer and the monitor on the board
## SW0
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { data_in }]
## SW1
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports { strb_in }]
## SW2
set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS33 } [get_ports { ack_in }]

## Bitstream config
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
