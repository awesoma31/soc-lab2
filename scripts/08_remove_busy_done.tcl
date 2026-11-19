# Lab 2, variant 3: remove the busy and done ports (the monitor times the algorithm by the protocol).
#   vivado -mode batch -source C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/08_remove_busy_done.tcl

set proj_dir [file normalize [file join [file dirname [info script]] ..]]
if {[current_project -quiet] eq ""} { open_project [file join $proj_dir lab2.xpr] }
update_compile_order -fileset sources_1

set bd_file [get_files design_1.bd]
open_bd_design $bd_file

set ports [get_bd_ports -quiet {busy done}]
if {$ports ne ""} {
    set nets [get_bd_nets -quiet -of_objects $ports]
    if {$nets ne ""} { delete_bd_objs $nets }
    delete_bd_objs $ports
}
update_module_reference [get_ips -quiet *gpio_if_0*]

validate_bd_design
save_bd_design

make_wrapper -files $bd_file -top
generate_target all $bd_file
export_ip_user_files -of_objects $bd_file -no_script -sync -force -quiet
write_hwdef -force -file [file join $proj_dir lab2.sdk design_1_wrapper.hdf]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "STEP8 DONE: ports = [lsort [get_bd_ports]]"
