vlib work

vlog -sv -work work rtl/execute.v +incdir+rtl
vlog -sv -work work rtl/alu.v +incdir+rtl
vlog -sv -work work testbench/execute_tb.v +incdir+rtl

vsim -t 100ps -lib work execute_tb

view wave
add wave clk
add wave dut/a_exec_next
add wave dut/b_exec_next
add wave dut/y_mem_next
add wave dut/alu0/fn
add wave dut/opcode
add wave dut/fn

restart -f

run -all