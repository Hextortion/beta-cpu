vlib work

vlog -sv +incdir+rtl -work work rtl/core.v
vlog -sv +incdir+rtl -work work rtl/fetch.v
vlog -sv +incdir+rtl -work work rtl/operand_mux.v
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
add wave -divider -height 20
add wave -hexadecimal dut/fetch0/ir_next
add wave -hexadecimal dut/decode0/ir_decode
add wave -hexadecimal dut/execute0/ir_exec
add wave -hexadecimal dut/mem_access0/ir_mem
add wave -hexadecimal dut/wb0/ir_wb
add wave -divider -height 20
add wave -decimal dut/a_decode
add wave -decimal dut/b_decode
add wave -decimal dut/y_exec
add wave -decimal dut/y_mem
add wave -decimal dut/rf_w_data
add wave -decimal dut/rf_w_addr
add wave -divider -height 20
add wave -decimal dut/decode0/rf/mem
add wave -divide -height 20
add wave -decimal dut/execute0/d_exec
add wave -decimal dut/mem_access0/d_mem
add wave -decimal dut/mem_access0/y_mem
add wave -divide -height 20
add wave d_mem

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

run 15us