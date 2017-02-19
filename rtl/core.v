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
    output logic [31:0] d_mem_we,       // data memory write enable
    output logic [31:0] d_mem_oe        // data memory output enable
);

logic stall;
logic zr;
logic op_jmp;
logic op_beq;
logic op_bne;

logic [31:0] br_addr;
logic [31:0] j_addr;

logic [31:0] pc_fetch;
logic [31:0] pc_decode;
logic [31:0] pc_exec;
logic [31:0] pc_mem;

logic [31:0] ir_fetch;
logic [31:0] ir_decode;
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

logic op_st_decode;
logic op_st_exec;
logic op_st_mem;

logic op_ld_or_ldr_decode;
logic op_ld_or_ldr_exec;
logic op_ld_or_ldr_mem;
logic op_ld_or_ldr_wb;

logic rf_w_mux_jump_decode;
logic rf_w_mux_jump_exec;
logic rf_w_mux_jump_mem;

fetch fetch0(
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .zr(zr),
    .irq(1'b0),
    .ir_src_rf(`IR_SRC_DATA),
    .ill_op(1'b0),
    .op_jmp(op_jmp),
    .op_beq(op_beq),
    .op_bne(op_bne),
    .br_addr(br_addr),
    .j_addr(j_addr),
    .i_mem_data(i_mem_data),
    .i_mem_addr(i_mem_addr),
    .pc_next(pc_fetch),
    .ir_next(ir_fetch)
);

decode decode0(
    .clk(clk),
    .pc(pc_fetch),
    .ir(ir_fetch),
    .jump_addr(j_addr),
    .branch_addr(br_addr),
    .d_next(d_exec),
    .a_next(a_exec),
    .b_next(b_exec),
    .pc_next(pc_decode),
    .ir_next(ir_decode),
    .op_ld_or_st(op_ld_or_st),
    .op_ldr(op_ldr),
    .op_jmp(op_jmp),
    .op_beq(op_beq),
    .op_bne(op_bne),
    .ir_src_dec(`IR_SRC_DATA),
    .zr(zr),
    .op_ld_or_ldr_next(op_ld_or_ldr_decode),
    .op_st_next(op_st_decode),
    .rf_w_mux_jump_next(rf_w_mux_jump_decode),
    .op_ld_or_ldr_exec(op_ld_or_ldr_exec),
    .op_ld_or_ldr_mem(op_ld_or_ldr_mem),
    .op_ld_or_ldr_wb(op_ld_or_ldr_wb),
    .ir_exec(ir_exec),
    .ir_mem(ir_mem),
    .ir_wb(ir_wb),
    .ex_bypass(y_exec),
    .mem_bypass(y_mem),
    .wb_bypass(rf_w_data),
    .rf_w_addr(rf_w_addr),
    .rf_w_data(rf_w_data),
    .rf_we(rf_we)
);

execute execute0(
    .clk(clk),
    .ir_src_exec(`IR_SRC_DATA),
    .op_st(op_st_decode),
    .op_st_next(op_st_exec),
    .rf_w_mux_jump(rf_w_mux_jump_decode),
    .rf_w_mux_jump_next(rf_w_mux_jump_exec),
    .op_ld_or_st(op_ld_or_st),
    .op_ld_or_ldr(op_ld_or_ldr),
    .op_ldr(op_ldr),
    .op_ld_or_ldr_next(op_ld_or_ldr_exec),
    .pc(pc_decode),
    .ir(ir_decode),
    .a(a_decode),
    .b(b_decode),
    .d(d_decode),
    .pc_next(pc_exec),
    .ir_next(ir_exec),
    .d_next(d_exec)
);

mem_access mem_access0(
    .clk(clk),
    .ir_src_mem(`IR_SRC_DATA),
    .mem_oe(d_mem_oe),
    .mem_wr(d_mem_wr),
    .op_ld_or_ldr(op_ld_or_ldr_exec),
    .op_ld_or_ldr_next(op_ld_or_ldr_mem),
    .op_st(op_st_exec),
    .op_st_next(op_st_mem),
    .rf_w_mux_jump(rf_w_mux_jump_exec),
    .rf_w_mux_jump_next(rf_w_mux_jump_mem),
    .pc(pc_exec),
    .ir(ir_exec),
    .y(y_exec),
    .d(d_exec),
    .pc_next(pc_mem),
    .ir_next(ir_mem),
    .y_next(y_mem)
);

wb wb0(
    .clk(clk),
    .op_ld_or_ldr(op_ld_or_ldr_exec),
    .op_ld_or_ldr_next(op_ld_or_ldr_wb),
    .op_st(op_st_mem),
    .rf_w_mux_jump(rf_w_mux_jump_mem),
    .pc(pc_mem),
    .ir(ir_mem),
    .y(y_mem),
    .mem_rd(d_mem_r_data),
    .rf_w_data(rf_w_data),
    .rf_w_addr(rf_w_addr)
);

endmodule
