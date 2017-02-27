///////////////////////////////////////////////////////////////////////////////
// File name: wb.v
// Author: Stefan Dumitrescu
// 
// Description: Implements the write back stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module wb(
    input clk,                        // clock

    output op_st,                     // IR is ST

    // datapath signals
    input [31:0] pc,                  // next pc value for this stage
    input [31:0] ir,                  // next ir value for this stage
    input [31:0] y,                   // next y value for this stage
    input [31:0] mem_rd,              // output of memory read
    output [31:0] ir_next,            // next ir value for next stage

    output reg [31:0] rf_w_data,      // reg file write data
    output [4:0] rf_w_addr,           // reg file write address
    output rf_we                      // reg file write enable
);

reg [31:0] pc_wb;
reg [31:0] ir_wb;
reg [31:0] y_wb;
reg [31:0] mem_rd_wb;

wire [5:0] opcode;
wire op_ld;
wire op_jmp;
wire op_beq;
wire op_bne;
wire op_ldr;
wire op_ld_or_ldr;
wire op_br_or_jmp;

///////////////////////////////////////////////////////////////////////////////
// Opcode Table (columns = opcode[2:0], rows = opcode[5:3])
//     | 000  | 001  | 010  | 011   | 100    | 101    | 110    | 111 |
// 000 |      |      |      |       |        |        |        |     |
// 001 |      |      |      |       |        |        |        |     |
// 010 |      |      |      |       |        |        |        |     |
// 011 | LD   | ST   |      | JMP   | BEQ    | BNE    |        | LDR |
// 100 | ADD  | SUB  |      |       | CMPEQ  | CMPLT  | CMPLE  |     |
// 101 | AND  | OR   | XOR  | XNOR  | SHL    | SHR    | SRA    |     |
// 110 | ADDC | SUBC |      |       | CMPEQC | CMPLTC | CMPLEC |     |
// 111 | ANDC | ORC  | XORC | XNORC | SHLC   | SHRC   | SRAC   |     |
///////////////////////////////////////////////////////////////////////////////

assign opcode = ir_wb[31:26];
assign op_st = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
assign op_ld = !opcode[5] && !opcode[2] && !opcode[1] && !opcode[0];
assign op_jmp = !opcode[5] && !opcode[2] && opcode[1] && opcode[0];
assign op_beq = !opcode[5] && opcode[2] && !opcode[1] && !opcode[0];
assign op_bne = !opcode[5] && opcode[2] && !opcode[1] && opcode[0];
assign op_br_or_jmp = op_jmp | op_bne | op_beq;
assign op_ldr = opcode[0] && opcode[1] && opcode[2];
assign op_ld_or_ldr = op_ldr || op_ld;

assign rf_we = !op_st;
assign rf_w_addr = ir_wb[25:21];
assign ir_next = ir_wb;

always @(*) begin
    case ({opcode[5], op_ld_or_ldr, op_br_or_jmp})
        5'b100: rf_w_data = y_wb;
        5'b010: rf_w_data = mem_rd_wb;        
        5'b001: rf_w_data = pc_wb;
        default: rf_w_data = 32'bx;
    endcase    
end

always @(posedge clk) begin
    pc_wb <= pc;
    ir_wb <= ir;
    y_wb <= y;
    mem_rd_wb <= mem_rd;
end

endmodule