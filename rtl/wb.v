///////////////////////////////////////////////////////////////////////////////
//  File name: mem_access.v
//  Author: Stefan Dumitrescu
//  
//  Description: Implements the write back stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module wb(
    input logic clk,                        // clock

    // datapath signals
    input logic [31:0] pc_wb_next,          // next pc value for this stage
    input logic [31:0] ir_wb_next,          // next ir value for this stage
    input logic [31:0] y_wb_next,           // next y value for this stage
    input logic [31:0] mem_rd,              // output of memory read

    output logic [31:0] rf_wd,              // reg file write data
    output logic [5:0] rf_wa,               // reg file write address
);

logic [31:0] pc_wb;
logic [31:0] ir_wb;
logic [31:0] y_wb;
logic [31:0] st_wb;

always_ff @(posedge clk) begin
    pc_wb <= pc_wb_next;
    ir_wb <= ir_wb_next;
    y_wb <= y_wb_next;
    st_wb <= st_wb_next;
end

always_comb begin
    // instruction register mux
    case (wd_sel)
        `WD_SRC_MEM: rf_wd = mem_rd;
        `WD_SRC_Y: rf_wd = y_wb;
        `WD_SRC_PC: rf_wd = pc_wb;
        default: rf_wd = 'x;
    endcase
end