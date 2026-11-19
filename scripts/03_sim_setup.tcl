# Lab 2, step 3: simulation fileset for the verification environment.
#   sim_1: sequencer.sv, monitor.sv, lab2_tb.sv (top lab2_tb); lab0_tb.v disabled.
# Run in the Vivado Tcl console with lab2.xpr open, or in batch mode:
#   vivado -mode batch -source C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/03_sim_setup.tcl

set proj_dir [file normalize [file join [file dirname [info script]] ..]]

if {[current_project -quiet] eq ""} {
    open_project [file join $proj_dir lab2.xpr]
}

set sim_dir [file join $proj_dir lab2.srcs sim_1 new]
set new_files [list \
    [file join $sim_dir sequencer.sv] \
    [file join $sim_dir monitor.sv] \
    [file join $sim_dir lab2_tb.sv] \
]
foreach f $new_files {
    if {[get_files -quiet -of_objects [get_filesets sim_1] $f] eq ""} {
        add_files -fileset sim_1 -norecurse $f
    }
}

set old_tb [get_files -quiet -of_objects [get_filesets sim_1] *lab0_tb.v]
if {$old_tb ne ""} {
    set_property is_enabled false $old_tb
}

set_property top lab2_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.xsim.more_options} -value {-sv_seed random} -objects [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "STEP3 DONE: sim_1 top = [get_property top [get_filesets sim_1]]"
