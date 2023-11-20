@REM ------------------------------------------------------
@REM Simple DOS batch file to compile and run the testbench
@REM Ver 1.0 HT-Lab 2002
@REM ------------------------------------------------------
vlib work

@REM Compile HTL8255 Tri-State version

vcom -93 -quiet -work work ../rtl/intra_fsm.vhd
vcom -93 -quiet -work work ../rtl/intrb_fsm.vhd
vcom -93 -quiet -work work ../rtl/htl8255.vhd
vcom -93 -quiet -work work ../rtl/htl8255_tri.vhd

@REM Compile Testbench

vcom -93 -quiet -work work ../testbench/utils.vhd
vcom -93 -quiet -work work ../testbench/htl8255_tri_tester.vhd
vcom -93 -quiet -work work ../testbench/htl8255_tri_tb.vhd

@REM Run simulation
vsim -c HTL8255_TriState_tb -do "set StdArithNoWarnings 1; run 100 us; quit"
