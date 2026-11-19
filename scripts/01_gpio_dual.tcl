# Lab 2, step 1: AXI GPIO -> dual channel.
#   Channel 1 (0x40000000, GPIO_DATA)  : 16 bit, All Outputs -> gpio_rtl_0_tri_o (LD0..LD15, as in lab 1)
#   Channel 2 (0x40000008, GPIO2_DATA) : 16 bit, All Inputs  -> seq_in_tri_i      (from the sequencer)
#
# Run either in the Vivado GUI Tcl console with lab2.xpr open:
#   source C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/01_gpio_dual.tcl
# or in batch mode (project closed in the GUI):
#   vivado -mode batch -source C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/01_gpio_dual.tcl

set proj_dir [file normalize [file join [file dirname [info script]] ..]]

if {[current_project -quiet] eq ""} {
    open_project [file join $proj_dir lab2.xpr]
}

set bd_file [get_files design_1.bd]
open_bd_design $bd_file

set gpio [get_bd_cells axi_gpio_0]
set_property -dict [list \
    CONFIG.C_IS_DUAL      {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_ALL_OUTPUTS_2 {0} \
    CONFIG.C_GPIO2_WIDTH  {16} \
] $gpio

if {[get_bd_intf_ports -quiet seq_in] eq ""} {
    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 seq_in
    connect_bd_intf_net [get_bd_intf_pins axi_gpio_0/GPIO2] [get_bd_intf_ports seq_in]
}

validate_bd_design
save_bd_design

# Wrapper is managed by Vivado (lives in the bd hdl folder) -> regenerate it.
make_wrapper -files $bd_file -top
generate_target all $bd_file
export_ip_user_files -of_objects $bd_file -no_script -sync -force -quiet

# Hardware description for SDK (no bitstream needed for simulation).
write_hwdef -force -file [file join $proj_dir lab2.sdk design_1_wrapper.hdf]

puts "STEP1 DONE: axi_gpio_0 is dual channel, port seq_in_tri_i\[15:0\] added"
