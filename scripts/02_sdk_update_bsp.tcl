# Lab 2, step 2: update SDK hardware platform and BSP after the GPIO change.
#   xsct C:/Users/gwert/ITMO_Labs/soc/lab2/scripts/02_sdk_update_bsp.tcl
set sdk_dir [file normalize [file join [file dirname [info script]] .. lab2.sdk]]

setws $sdk_dir
updatehw -hw design_1_wrapper_hw_platform_0 -newhwspec [file join $sdk_dir design_1_wrapper.hdf]
regenbsp -bsp lab1-project_bsp
projects -build -type bsp -name lab1-project_bsp
puts "STEP2 BSP DONE"
