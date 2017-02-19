///////////////////////////////////////////////////////////////////////////////
//  File name: mem_access.v
//  Author: Stefan Dumitrescu
//  
//  Description: Implements the write back stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module wb(
    input logic clk,                        // clock

    // control signals
    input logic op_ld_or_ldr,               // next op_ld_or_ldr value for this stage
    output logic op_ld_or_ldr_next,         // next op_ld_or_ldr value

    // datapath signals
    input logic [31:0] pc,                  // next pc value for this stage
    input logic [31:0] ir,                  // next ir value for this stage
    input logic [31:0] y,                   // next y value for this stage
    input logic [31:0] mem_rd,              // output of memory read

    output logic [31:0] rf_w_data,          // reg file write data
    output logic [4:0] rf_w_addr            // reg file write address
);

logic [31:0] pc_wb;
logic [31:0] ir_wb;
logic [31:0] y_wb;
logic [31:0] st_wb;
logic [31:0] wd_sel;

always_ff @(posedge clk) begin
    pc_wb <= pc;
    ir_wb <= ir;
    y_wb <= y;
    op_ld_or_ldr_next <= op_ld_or_ldr;
end

always_comb begin
    // instruction register mux
    case (wd_sel)
        `WD_SRC_MEM: rf_w_data = mem_rd;
        `WD_SRC_Y: rf_w_data = y_wb;
        `WD_SRC_PC: rf_w_data = pc_wb;
        default: rf_w_data = 'x;
    endcase
end

endmodule