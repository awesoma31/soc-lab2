# Lab 2, step 6: refresh compile order after adding the gpio_if module reference.
set proj_dir [file normalize [file join [file dirname [info script]] ..]]
if {[current_project -quiet] eq ""} { open_project [file join $proj_dir lab2.xpr] }
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
set f [get_files -all *sources_1/new/gpio_if.v]
puts "STEP6 gpio_if.v is_enabled=[get_property is_enabled $f] auto_disabled=[get_property is_auto_disabled $f]"
puts "STEP6 sim_1 compile order (tail):"
foreach x [lrange [get_files -compile_order sources -used_in simulation -of_objects [get_filesets sim_1]] end-6 end] { puts "  $x" }
