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
    input logic [1:0] ir_src_mem            // instruction register source
    input logic mem_oe,                     // memory output enable
    input logic mem_wr,                     // memory write enable
    input logic op_ld_or_ldr,               // next op_ld_or_ldr value for this stage
    output logic op_ld_or_ldr_next,         // next op_ld_or_ldr value for next stage

    // datapath signals
    input logic [31:0] pc,                  // next pc value for this stage
    input logic [31:0] ir,                  // next ir value for this stage
    input logic [31:0] y,                   // next y value for this stage
    input logic [31:0] d,                   // next st value for this stage

    output logic [31:0] pc_next,            // next pc value for the next stage
    output logic [31:0] ir_next,            // next ir value for the next stage
    output logic [31:0] y_next,             // next y value for the next stage
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
end

always_comb begin
    // instruction register mux
    case (ir_src_mem)
        `IR_SRC_EXCEPT: ir_next = `INST_BNE_EXCEPT;
        `IR_SRC_NOP: ir_next = `INST_NOP;
        `IR_SRC_DATA: ir_next = ir_mem;
        default: ir_next = 'x;
    endcase
end

endmodule




