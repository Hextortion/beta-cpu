onbreak {resume}

if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}

vlib rtl_work
vmap work rtl_work

vlog -sv -svinputport=var -work rtl_work rtl/alu.v
vlog -sv -svinputport=var -work rtl_work testbench/alu_tb.v

vsim -t 100ps -L altera_mf_ver -lib rtl_work alu_tb

restart -f

run -all