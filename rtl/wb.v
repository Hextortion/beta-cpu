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
    output logic [4:0] rf_w_addr,           // reg file write address
    output logic rf_we                      // reg file write enable
);

logic [31:0] pc_wb;
logic [31:0] ir_wb;
logic [31:0] y_wb;
logic [31:0] st_wb;
logic op_st;
logic op_jmp;
logic op_beq;
logic op_bne;
logic jump;
logic [5:0] opcode;

always_ff @(posedge clk) begin
    pc_wb <= pc;
    ir_wb <= ir;
    y_wb <= y;
    op_ld_or_ldr_next <= op_ld_or_ldr;
end

always_comb begin
    opcode = ir_wb[31:26];
    op_st = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
    op_jmp = !opcode[5] + !opcode[2] + opcode[1] + opcode[0];
    op_beq = !opcode[5] + opcode[2] + !opcode[1] + !opcode[0];
    op_bne = !opcode[5] + opcode[2] + !opcode[1] + opcode[0];
    jump = op_jmp || op_beq || op_bne;
    rf_we = !op_st;
    rf_w_addr = ir_wb[25:21];

    // instruction register mux
    case ({opcode[5], op_ld_or_ldr_next, jump}) inside
        5'b010: rf_w_data = mem_rd;
        5'b100: rf_w_data = y_wb;
        5'b001: rf_w_data = pc_wb;
        default: rf_w_data = 'x;
    endcase
end

endmodule