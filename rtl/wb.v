///////////////////////////////////////////////////////////////////////////////
//  File name: wb.v
//  Author: Stefan Dumitrescu
//  
//  Description: Implements the write back stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module wb(
    input logic clk,                        // clock

    output logic op_st,                     // this IR is ST

    // datapath signals
    input logic [31:0] pc,                  // next pc value for this stage
    input logic [31:0] ir,                  // next ir value for this stage
    input logic [31:0] y,                   // next y value for this stage
    input logic [31:0] mem_rd,              // output of memory read
    output logic [31:0] ir_next,            // next ir value for next stage

    output logic [31:0] rf_w_data,          // reg file write data
    output logic [4:0] rf_w_addr,           // reg file write address
    output logic rf_we                      // reg file write enable
);

logic [31:0] pc_wb;
logic [31:0] ir_wb;
logic [31:0] y_wb;
logic [31:0] mem_rd_wb;

logic [5:0] opcode;
logic op_ld;
logic op_jmp;
logic op_beq;
logic op_bne;
logic op_ldr;
logic op_ld_or_ldr;
logic op_br_or_jmp;

always_ff @(posedge clk) begin
    pc_wb <= pc;
    ir_wb <= ir;
    y_wb <= y;
    mem_rd_wb <= mem_rd;
end

always_comb begin
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
    opcode = ir_wb[31:26];
    op_st = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
    op_ld = !opcode[5] && !opcode[2] && !opcode[1] && !opcode[0];
    op_jmp = !opcode[5] && !opcode[2] && opcode[1] && opcode[0];
    op_beq = !opcode[5] && opcode[2] && !opcode[1] && !opcode[0];
    op_bne = !opcode[5] && opcode[2] && !opcode[1] && opcode[0];
    op_br_or_jmp = op_jmp | op_bne | op_beq;
    op_ldr = opcode[0] && opcode[1] && opcode[2];
    op_ld_or_ldr = op_ldr || op_ld;

    rf_we = !op_st;
    rf_w_addr = ir_wb[25:21];

    case ({opcode[5], op_ld_or_ldr, op_br_or_jmp})
        5'b100: rf_w_data = y_wb;
        5'b010: rf_w_data = mem_rd_wb;        
        5'b001: rf_w_data = pc_wb;
        default: rf_w_data = 'x;
    endcase

    ir_next = ir_wb;
end

endmodule