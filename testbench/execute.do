vlib work

vlog -sv -work work rtl/execute.v +incdir+rtl
vlog -sv -work work rtl/alu.v +incdir+rtl
vlog -sv -work work testbench/execute_tb.v +incdir+rtl

vsim -t 100ps -lib work execute_tb

restart -f

run -all