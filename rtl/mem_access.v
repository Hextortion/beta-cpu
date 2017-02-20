///////////////////////////////////////////////////////////////////////////////
//  File name: mem_access.v
//  Author: Stefan Dumitrescu
//  
//  Description: Implements the memory access stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module mem_access(
    input logic clk,                        // clock

    // control signals
    input logic [1:0] ir_src_mem,           // instruction register source
    output logic mem_wr,                    // memory write enable
    output logic [31:0] mem_w_data,         // memory write data
    output logic [31:0] mem_w_addr,         // memory write address
    input logic op_st,                      // next op_st value for this stage
    output logic op_st_next,                // next op_st value for next stage
    input logic op_ld_or_ldr,               // next op_ld_or_ldr value for this stage
    output logic op_ld_or_ldr_next,         // next op_ld_or_ldr value for next stage
    input logic rf_w_mux_jump,              // next rf_w_mux_jump value for this stage
    output logic rf_w_mux_jump_next,        // next rf_w_mux_jump value for next stage

    // datapath signals
    input logic [31:0] pc,                  // next pc value for this stage
    input logic [31:0] ir,                  // next ir value for this stage
    input logic [31:0] y,                   // next y value for this stage
    input logic [31:0] d,                   // next st value for this stage

    output logic [31:0] pc_next,            // next pc value for the next stage
    output logic [31:0] ir_next,            // next ir value for the next stage
    output logic [31:0] y_next              // next y value for the next stage
);

logic [31:0] pc_mem;
logic [31:0] ir_mem;
logic [31:0] y_mem;
logic [31:0] d_mem;

always_ff @(posedge clk) begin
    pc_mem <= pc;
    ir_mem <= ir;
    y_mem <= y;
    d_mem <= d;
    op_ld_or_ldr_next <= op_ld_or_ldr;
    op_st_next <= op_st;
    rf_w_mux_jump_next <= rf_w_mux_jump;
end

always_comb begin
    // instruction register mux
    case (ir_src_mem)
        `IR_SRC_EXCEPT: ir_next = `INST_BNE_EXCEPT;
        `IR_SRC_NOP: ir_next = `INST_NOP;
        `IR_SRC_DATA: ir_next = ir_mem;
        default: ir_next = 'x;
    endcase

    pc_next = pc_mem;
    y_next = y_mem;
    mem_wr = op_st_next;

    mem_w_addr = y_mem;
    mem_w_data = d_mem;
end

endmodule




