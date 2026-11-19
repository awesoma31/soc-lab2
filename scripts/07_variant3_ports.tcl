# Lab 2, variant 3: serial ports on gpio_if_0.
#   in : data_in, strb_in, ack_in      out: data_out, strb_out, ack_out, busy, done
#   vivado -mode batch -source C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/07_variant3_ports.tcl

set proj_dir [file normalize [file join [file dirname [info script]] ..]]
if {[current_project -quiet] eq ""} { open_project [file join $proj_dir lab2.xpr] }
update_compile_order -fileset sources_1

set bd_file [get_files design_1.bd]
open_bd_design $bd_file

set cells [get_bd_cells -quiet gpio_if_0]
set ports [get_bd_ports -quiet {data_in strb_in ack_in data_out strb_out ack ack_out busy done}]
set nets {}
if {$cells ne ""} { set nets [concat $nets [get_bd_nets -quiet -of_objects $cells]] }
if {$ports ne ""} { set nets [concat $nets [get_bd_nets -quiet -of_objects $ports]] }
set nets [lsort -unique $nets]
if {$nets  ne ""} { delete_bd_objs [get_bd_nets $nets] }
if {$cells ne ""} { delete_bd_objs $cells }
if {$ports ne ""} { delete_bd_objs $ports }

create_bd_cell -type module -reference gpio_if gpio_if_0
# re-read gpio_if.v, otherwise the cached (old) port list is used
update_module_reference [get_ips -quiet *gpio_if_0*]
connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins gpio_if_0/gpio_o]
connect_bd_net [get_bd_pins gpio_if_0/gpio2_i]    [get_bd_pins axi_gpio_0/gpio2_io_i]

foreach p {data_in strb_in ack_in} {
    create_bd_port -dir I $p
    connect_bd_net [get_bd_ports $p] [get_bd_pins gpio_if_0/$p]
}
foreach p {data_out strb_out ack_out busy done} {
    create_bd_port -dir O $p
    connect_bd_net [get_bd_pins gpio_if_0/$p] [get_bd_ports $p]
}

regenerate_bd_layout
validate_bd_design
save_bd_design

make_wrapper -files $bd_file -top
generate_target all $bd_file
export_ip_user_files -of_objects $bd_file -no_script -sync -force -quiet
write_hwdef -force -file [file join $proj_dir lab2.sdk design_1_wrapper.hdf]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "STEP7 DONE: gpio_if.v enabled=[get_property is_enabled [get_files -all *sources_1/new/gpio_if.v]]"
