transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/Digital_Logic_Design/Normal/Homework\ 3/Normal_HW3 {D:/Digital_Logic_Design/Normal/Homework 3/Normal_HW3/edge_detect.v}
vlog -vlog01compat -work work +incdir+D:/Digital_Logic_Design/Normal/Homework\ 3/Normal_HW3 {D:/Digital_Logic_Design/Normal/Homework 3/Normal_HW3/AM2302_master.v}

