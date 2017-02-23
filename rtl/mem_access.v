///////////////////////////////////////////////////////////////////////////////
//  File name: mem_access.v
//  Author: Stefan Dumitrescu
//  
//  Description: Implements the memory access stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module mem_access(
    input logic clk,                        // clock

    output logic op_ld_or_ldr,              // this IR is LD or LDR
    output logic op_st,                     // this IR is ST
    output logic op_br_or_jmp,              // this IR is BR or JMP

    // datapath signals
    input logic [31:0] pc,                  // next pc value for this stage
    input logic [31:0] ir,                  // next ir value for this stage
    input logic [31:0] y,                   // next y value for this stage
    input logic [31:0] d,                   // next st value for this stage

    output logic [31:0] pc_next,            // next pc value for the next stage
    output logic [31:0] ir_next,            // next ir value for the next stage
    output logic [31:0] y_next,             // next y value for the next stage

    // external memory signals
    output logic mem_wr,                    // memory write enable
    output logic [31:0] mem_w_data,         // memory write data
    output logic [31:0] mem_w_addr          // memory write address
);

logic [31:0] pc_mem;
logic [31:0] ir_mem;
logic [31:0] y_mem;
logic [31:0] d_mem;

logic [5:0] opcode;
logic op_ld;
logic op_jmp;
logic op_beq;
logic op_bne;
logic op_ldr;

logic preceding_exception;
logic current_exception;

always_ff @(posedge clk) begin
    pc_mem <= pc;
    ir_mem <= ir;
    y_mem <= y;
    d_mem <= d;
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
    opcode = ir_mem[31:26];
    op_st = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
    op_ld = !opcode[5] && !opcode[2] && !opcode[1] && !opcode[0];
    op_jmp = !opcode[5] && !opcode[2] && opcode[1] && opcode[0];
    op_beq = !opcode[5] && opcode[2] && !opcode[1] && !opcode[0];
    op_bne = !opcode[5] && opcode[2] && !opcode[1] && opcode[0];
    op_br_or_jmp = op_jmp | op_bne | op_beq;
    op_ldr = opcode[0] && opcode[1] && opcode[2];
    op_ld_or_ldr = op_ldr || op_ld;

    preceding_exception = 1'b0;
    current_exception = 1'b0;

    if (preceding_exception) begin
        ir_next = `INST_NOP;
    end else begin
        if (current_exception) begin
            ir_next = `INST_BNE_EXCEPT;
        end else begin
            ir_next = ir_mem;
        end
    end

    pc_next = pc_mem;
    y_next = y_mem;
    mem_wr = op_st;

    mem_w_addr = y_mem;
    mem_w_data = d_mem;
end

endmodule