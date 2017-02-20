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
add wave dut/stall
add wave -divider -height 10
add wave -hexadecimal dut/ir_fetch
add wave -hexadecimal dut/ir_decode
add wave -hexadecimal dut/ir_exec
add wave -hexadecimal dut/ir_mem
add wave -hexadecimal dut/ir_wb
add wave -divider -height 10
add wave -hexadecimal dut/fetch0/pc_fetch
add wave -hexadecimal dut/decode0/pc_decode
add wave -hexadecimal dut/pc_decode
add wave -hexadecimal dut/pc_exec
add wave -hexadecimal dut/pc_mem
add wave -divider -height 10
add wave -decimal dut/a_decode
add wave -decimal dut/b_decode
add wave -decimal dut/y_exec
add wave -decimal dut/y_mem
add wave -decimal dut/rf_w_data
add wave -divider -height 10
add wave -decimal dut/decode0/rf/mem

# add wave -divider -height 10
# add wave dut/fetch0/*
# add wave -divider -height 10
# add wave dut/decode0/*
# add wave -divider -height 10
# add wave dut/decode0/rf/*
# add wave -divider -height 10
# add wave dut/execute0/*
# add wave -divider -height 10
# add wave dut/mem_access0/*
# add wave -divider -height 10
# add wave dut/wb0/*

run 20us