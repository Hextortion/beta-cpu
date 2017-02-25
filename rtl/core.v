///////////////////////////////////////////////////////////////////////////////
//  File name: core.v
//  Author: Stefan Dumitrescu
//  
//  Description: Connects all stages of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module core(
    // clock and reset
    input logic clk,                    // clock
    input logic rst,                    // reset

    // memory signals
    input logic [31:0] i_mem_r_data,    // instruction memory read data
    output logic [31:0] i_mem_r_addr,   // instruction memory read address
    output logic [31:0] d_mem_w_data,   // data memory write data
    output logic [31:0] d_mem_w_addr,   // data memory write address
    input logic [31:0] d_mem_r_data,    // data memory read data
    output logic d_mem_we,              // data memory write enable
    output logic d_mem_oe               // data memory output enable
);

logic stall;
logic zr;
logic op_jmp;
logic op_beq;
logic op_bne;
logic op_ill;

logic [31:0] br_addr;
logic [31:0] j_addr;

logic [31:0] pc_fetch;
logic [31:0] pc_decode;
logic [31:0] pc_exec;
logic [31:0] pc_mem;

logic [31:0] ir_fetch;
logic [31:0] ir_decode;
logic [31:0] ir_exec;
logic [31:0] ir_mem;
logic [31:0] ir_wb;

logic [31:0] d_decode;
logic [31:0] d_exec;
logic [31:0] a_decode;
logic [31:0] b_decode;

logic [31:0] y_exec;
logic [31:0] y_mem;

logic [4:0] rf_w_addr;
logic [31:0] rf_w_data;
logic rf_we;

logic op_st_ex;
logic op_st_mem;
logic op_st_wb;

logic op_ld_or_ldr_ex;
logic op_ld_or_ldr_mem;

logic op_br_or_jmp_ex;
logic op_br_or_jmp_mem;

fetch fetch0(
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .zr(zr),
    .irq(1'b0),
    .op_ill(1'b0),
    .op_jmp(op_jmp),
    .op_beq(op_beq),
    .op_bne(op_bne),
    .br_addr(br_addr),
    .j_addr(j_addr),
    .i_mem_data(i_mem_r_data),
    .i_mem_addr(i_mem_r_addr),
    .pc_next(pc_fetch),
    .ir_next(ir_fetch)
);

decode decode0(
    .clk(clk),
    .rst(rst),
    .pc(pc_fetch),
    .ir(ir_fetch),
    .d_next(d_decode),
    .a_next(a_decode),
    .b_next(b_decode),
    .pc_next(pc_decode),
    .ir_next(ir_decode),
    .op_ill(op_ill),
    .op_jmp(op_jmp),
    .op_beq(op_beq),
    .op_bne(op_bne),
    .zr(zr),
    .j_addr(j_addr),
    .br_addr(br_addr),
    .stall(stall),
    .op_ld_or_ldr_ex(op_ld_or_ldr_ex),
    .op_ld_or_ldr_mem(op_ld_or_ldr_mem),
    .op_br_or_jmp_ex(op_br_or_jmp_ex),
    .op_br_or_jmp_mem(op_br_or_jmp_mem),
    .op_st_ex(op_st_ex),
    .op_st_mem(op_st_mem),
    .op_st_wb(op_st_wb),
    .rc_ex(ir_exec[25:21]),
    .rc_mem(ir_mem[25:21]),
    .rc_wb(ir_wb[25:21]),
    .ex_y_bypass(y_exec),
    .ex_pc_bypass(pc_exec),
    .mem_y_bypass(y_mem),
    .mem_pc_bypass(pc_mem),
    .wb_bypass(rf_w_data),
    .rf_w_addr(rf_w_addr),
    .rf_w_data(rf_w_data),
    .rf_we(rf_we)
);

execute execute0(
    .clk(clk),
    .op_ld_or_ldr(op_ld_or_ldr_ex),
    .op_st(op_st_ex),
    .op_br_or_jmp(op_br_or_jmp_ex),
    .pc(pc_decode),
    .ir(ir_decode),
    .a(a_decode),
    .b(b_decode),
    .d(d_decode),
    .pc_next(pc_exec),
    .ir_next(ir_exec),
    .y_next(y_exec),
    .d_next(d_exec)
);

mem_access mem_access0(
    .clk(clk),
    .op_ld_or_ldr(op_ld_or_ldr_mem),
    .op_st(op_st_mem),
    .op_br_or_jmp(op_br_or_jmp_mem),
    .pc(pc_exec),
    .ir(ir_exec),
    .y(y_exec),
    .d(d_exec),
    .pc_next(pc_mem),
    .ir_next(ir_mem),
    .y_next(y_mem),
    .mem_wr(d_mem_we),
    .mem_w_data(d_mem_w_data),
    .mem_w_addr(d_mem_w_addr)
);

wb wb0(
    .clk(clk),
    .op_st(op_st_wb),
    .pc(pc_mem),
    .ir(ir_mem),
    .y(y_mem),
    .ir_next(ir_wb),
    .mem_rd(d_mem_r_data),
    .rf_w_data(rf_w_data),
    .rf_w_addr(rf_w_addr),
    .rf_we(rf_we)
);

endmodule
