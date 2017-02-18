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

    // datapath signals
    input logic [31:0] pc_mem_next,         // next pc value for this stage
    input logic [31:0] ir_mem_next,         // next ir value for this stage
    input logic [31:0] y_mem_next,          // next y value for this stage
    input logic [31:0] st_mem_next,         // next st value for this stage

    output logic [31:0] pc_wb_next,         // next pc value for the next stage
    output logic [31:0] ir_wb_next,         // next ir value for the next stage
    output logic [31:0] y_wb_next,          // next y value for the next stage

    output logic [31:0] mem_rd              // output of memory read
);

logic [31:0] pc_mem;
logic [31:0] ir_mem;
logic [31:0] y_mem;
logic [31:0] st_mem;

always_ff @(posedge clk) begin
    pc_mem <= pc_mem_next;
    ir_mem <= ir_mem_next;
    y_mem <= y_mem_next;
    st_mem <= st_mem_next;
end

always_comb begin
    // instruction register mux
    case (ir_src_mem)
        `IR_SRC_EXCEPT: ir_wb_next = `INST_BNE_EXCEPT;
        `IR_SRC_NOP: ir_wb_next = `INST_NOP;
        `IR_SRC_DATA: ir_wb_next = ir_mem;
        default: ir_wb_next = 'x;
    endcase
end

endmodule




