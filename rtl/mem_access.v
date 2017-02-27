///////////////////////////////////////////////////////////////////////////////
// File name: mem_access.v
// Author: Stefan Dumitrescu
// 
// Description: Implements the memory access stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module mem_access(
    input clk,                        // clock

    output op_ld_or_ldr,              // this IR is LD or LDR
    output op_st,                     // this IR is ST
    output op_br_or_jmp,              // this IR is BR or JMP

    // datapath signals
    input [31:0] pc,                  // next pc value for this stage
    input [31:0] ir,                  // next ir value for this stage
    input [31:0] y,                   // next y value for this stage
    input [31:0] d,                   // next st value for this stage

    output [31:0] pc_next,            // next pc value for the next stage
    output reg [31:0] ir_next,        // next ir value for the next stage
    output [31:0] y_next,             // next y value for the next stage

    // external memory signals
    output mem_wr,                    // memory write enable
    output [31:0] mem_w_data,         // memory write data
    output [31:0] mem_w_addr          // memory write address
);

reg [31:0] pc_mem;
reg [31:0] ir_mem;
reg [31:0] y_mem;
reg [31:0] d_mem;

wire [5:0] opcode;
wire op_ld;
wire op_jmp;
wire op_beq;
wire op_bne;
wire op_ldr;

wire preceding_exception;
wire current_exception;

always @(posedge clk) begin
    pc_mem <= pc;
    ir_mem <= ir;
    y_mem <= y;
    d_mem <= d;
end

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

assign opcode = ir_mem[31:26];
assign op_st = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
assign op_ld = !opcode[5] && !opcode[2] && !opcode[1] && !opcode[0];
assign op_jmp = !opcode[5] && !opcode[2] && opcode[1] && opcode[0];
assign op_beq = !opcode[5] && opcode[2] && !opcode[1] && !opcode[0];
assign op_bne = !opcode[5] && opcode[2] && !opcode[1] && opcode[0];
assign op_br_or_jmp = op_jmp | op_bne | op_beq;
assign op_ldr = opcode[0] && opcode[1] && opcode[2];
assign op_ld_or_ldr = op_ldr || op_ld;

assign preceding_exception = 1'b0;
assign current_exception = 1'b0;

assign pc_next = pc_mem;
assign y_next = y_mem;
assign mem_wr = op_st;

assign mem_w_addr = y_mem;
assign mem_w_data = d_mem;

always @(*) begin
    if (preceding_exception) begin
        ir_next = `INST_NOP;
    end else begin
        if (current_exception) begin
            ir_next = `INST_BNE_EXCEPT;
        end else begin
            ir_next = ir_mem;
        end
    end
end

endmodule