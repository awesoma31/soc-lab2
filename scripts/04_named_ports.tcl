# Lab 2, step 4: show the protocol signals in the block design as named ports.
#   GPIO channel 1 (outputs, 16 bit) is cut by Slice blocks:
#       [7:0] -> data_out[7:0], [8] -> strb_out, [9] -> ack, [10] -> busy, [11] -> done
#   GPIO channel 2 (inputs, 16 bit) is built by a Concat block:
#       {strb_in, 7'b0, data_in[7:0]}   (same layout as before, software unchanged)
#   The old interface ports gpio_rtl_0 and seq_in are removed.
#
# Run in the Vivado Tcl console with lab2.xpr open:
#   source C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/04_named_ports.tcl
# or in batch mode with the project closed:
#   vivado -mode batch -source C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/04_named_ports.tcl

set proj_dir [file normalize [file join [file dirname [info script]] ..]]

if {[current_project -quiet] eq ""} {
    open_project [file join $proj_dir lab2.xpr]
}

set bd_file [get_files design_1.bd]
open_bd_design $bd_file

# ---- remove the old interface ports
foreach p {gpio_rtl_0 seq_in} {
    set port [get_bd_intf_ports -quiet $p]
    if {$port ne ""} {
        delete_bd_objs [get_bd_intf_nets -quiet -of_objects $port] $port
    }
}

# ---- outputs: slices of gpio_io_o
proc add_slice {name from to port} {
    set s [create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 $name]
    set w [expr {$from - $to + 1}]
    set_property -dict [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM $from \
                             CONFIG.DIN_TO $to CONFIG.DOUT_WIDTH $w] $s
    connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins $name/Din]
    if {$w > 1} {
        create_bd_port -dir O -from [expr {$w - 1}] -to 0 $port
    } else {
        create_bd_port -dir O $port
    }
    connect_bd_net [get_bd_pins $name/Dout] [get_bd_ports $port]
}

add_slice slice_data_out  7  0 data_out
add_slice slice_strb_out  8  8 strb_out
add_slice slice_ack       9  9 ack
add_slice slice_busy     10 10 busy
add_slice slice_done     11 11 done

# ---- inputs: concat into gpio2_io_i
set c [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_seq_in]
set_property -dict [list CONFIG.NUM_PORTS {3} CONFIG.IN0_WIDTH {8} \
                         CONFIG.IN1_WIDTH {7} CONFIG.IN2_WIDTH {1}] $c

set z [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_zero7]
set_property -dict [list CONFIG.CONST_WIDTH {7} CONFIG.CONST_VAL {0}] $z

create_bd_port -dir I -from 7 -to 0 data_in
create_bd_port -dir I strb_in
connect_bd_net [get_bd_ports data_in]        [get_bd_pins concat_seq_in/In0]
connect_bd_net [get_bd_pins const_zero7/dout] [get_bd_pins concat_seq_in/In1]
connect_bd_net [get_bd_ports strb_in]        [get_bd_pins concat_seq_in/In2]
connect_bd_net [get_bd_pins concat_seq_in/dout] [get_bd_pins axi_gpio_0/gpio2_io_i]

regenerate_bd_layout
validate_bd_design
save_bd_design

make_wrapper -files $bd_file -top
generate_target all $bd_file
export_ip_user_files -of_objects $bd_file -no_script -sync -force -quiet
write_hwdef -force -file [file join $proj_dir lab2.sdk design_1_wrapper.hdf]

puts "STEP4 DONE: ports data_in, strb_in, data_out, strb_out, ack, busy, done"
