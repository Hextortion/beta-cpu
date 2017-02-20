vlib work

vlog -sv +incdir+rtl -work work rtl/core.v
vlog -sv +incdir+rtl -work work rtl/fetch.v
vlog -sv +incdir+rtl -work work rtl/defines.v
vlog -sv +incdir+rtl -work work rtl/reg_file.v
vlog -sv +incdir+rtl -work work rtl/decode.v
vlog -sv +incdir+rtl -work work rtl/alu.v
vlog -sv +incdir+rtl -work work rtl/execute.v
vlog -sv +incdir+rtl -work work rtl/mem_access.v
vlog -sv +incdir+rtl -work work rtl/wb.v
vlog -sv +incdir+rtl -work work testbench/core_tb.v

vsim -t 100ps -lib work core_tb

restart -f

view wave
add wave clk
add wave rst
add wave -divider -height 10
add wave dut/fetch0/*
add wave -divider -height 10
add wave dut/decode0/*
add wave -divider -height 10
add wave dut/decode0/rf/*
add wave -divider -height 10
add wave dut/execute0/*
add wave -divider -height 10
add wave dut/mem_access0/*
add wave -divider -height 10
add wave dut/wb0/*

run 1us