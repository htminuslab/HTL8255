vlib work
vcom -93 -quiet -work work ../rtl/intra_fsm.vhd
vcom -93 -quiet -work work ../rtl/intrb_fsm.vhd
vcom -93 -quiet -work work ../rtl/htl8255.vhd
vcom -93 -quiet -work work ../rtl/htl8255_tri.vhd
vcom -93 -quiet -work work ../testbench/utils.vhd
vcom -93 -quiet -work work ../testbench/htl8255_tri_tester.vhd
vcom -93 -quiet -work work ../testbench/htl8255_tri_tb.vhd
vsim HTL8255_TriState_tb 
set StdArithNoWarnings 1
run 100 us
