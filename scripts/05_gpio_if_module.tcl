# Lab 2, step 5: replace Slice / Concat / Constant blocks with one RTL block.
#   gpio_if (lab2.srcs/sources_1/new/gpio_if.v) is added as a module reference:
#   axi_gpio_0/gpio_io_o -> gpio_if_0/gpio_o, gpio_if_0/gpio2_i -> axi_gpio_0/gpio2_io_i,
#   and its pins go to the external ports data_in, strb_in, data_out, strb_out, ack, busy, done.
#
# Run in the Vivado Tcl console with lab2.xpr open:
#   source C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/05_gpio_if_module.tcl
# or in batch mode with the project closed:
#   vivado -mode batch -source C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/05_gpio_if_module.tcl

set proj_dir [file normalize [file join [file dirname [info script]] ..]]

if {[current_project -quiet] eq ""} {
    open_project [file join $proj_dir lab2.xpr]
}

set rtl [file join $proj_dir lab2.srcs sources_1 new gpio_if.v]
if {[get_files -quiet $rtl] eq ""} {
    add_files -fileset sources_1 -norecurse $rtl
}
update_compile_order -fileset sources_1

set bd_file [get_files design_1.bd]
open_bd_design $bd_file

# ---- remove the helper blocks of step 4 and the external ports
set helpers [get_bd_cells -quiet {slice_data_out slice_strb_out slice_ack slice_busy slice_done concat_seq_in const_zero7}]
set ports   [get_bd_ports -quiet {data_in strb_in data_out strb_out ack busy done}]
set nets    {}
if {$helpers ne ""} { set nets [concat $nets [get_bd_nets -quiet -of_objects $helpers]] }
if {$ports   ne ""} { set nets [concat $nets [get_bd_nets -quiet -of_objects $ports]] }
set nets [lsort -unique $nets]
if {$nets    ne ""} { delete_bd_objs [get_bd_nets $nets] }
if {$helpers ne ""} { delete_bd_objs $helpers }
if {$ports   ne ""} { delete_bd_objs $ports }

# ---- one block between AXI GPIO and the ports
create_bd_cell -type module -reference gpio_if gpio_if_0

connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins gpio_if_0/gpio_o]
connect_bd_net [get_bd_pins gpio_if_0/gpio2_i]    [get_bd_pins axi_gpio_0/gpio2_io_i]

create_bd_port -dir I -from 7 -to 0 data_in
create_bd_port -dir I strb_in
create_bd_port -dir O -from 7 -to 0 data_out
foreach p {strb_out ack busy done} { create_bd_port -dir O $p }

foreach p {data_in strb_in data_out strb_out ack busy done} {
    connect_bd_net [get_bd_ports $p] [get_bd_pins gpio_if_0/$p]
}

regenerate_bd_layout
validate_bd_design
save_bd_design

make_wrapper -files $bd_file -top
generate_target all $bd_file
export_ip_user_files -of_objects $bd_file -no_script -sync -force -quiet
write_hwdef -force -file [file join $proj_dir lab2.sdk design_1_wrapper.hdf]

puts "STEP5 DONE: gpio_if_0 between axi_gpio_0 and the protocol ports"
