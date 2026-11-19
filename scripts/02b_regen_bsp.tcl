# Lab 2, step 2b: regenerate and build the BSP (hw platform already updated).
set sdk_dir [file normalize [file join [file dirname [info script]] .. lab2.sdk]]
setws $sdk_dir
regenbsp -bsp lab1-project_bsp
projects -build -type bsp -name lab1-project_bsp
puts "STEP2 BSP DONE"
