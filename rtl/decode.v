///////////////////////////////////////////////////////////////////////////////
//  File name: decode.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the implementaion of decode stage
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module decode(
    // clock and reset
    input logic clk,                    // clock
    input logic rst,                    // reset

    // datapath signals
    input logic [31:0] pc,              // PC + 4
    input logic [31:0] ir,              // instruction that has been fetched

    output logic [31:0] j_addr,         // jump target address
    output logic [31:0] br_addr,        // branch target address
    output logic [31:0] d_next,         // store data for mem access stage

    output logic [31:0] a_next,         // output for register A in ALU stage
    output logic [31:0] b_next,         // output for register B in ALU stage

    output logic [31:0] pc_next,        // pc output for next stage
    output logic [31:0] ir_next,        // instruction output for next stage

    output logic op_ld_or_st,           // LD or ST control signal
    output logic op_ldr,                // LDR control signal
    output logic op_jmp,                // JMP control signal
    output logic op_beq,                // BEQ control signal
    output logic op_bne,                // BNE control signal

    // control signals
    input logic [1:0] ir_src_dec,       // source for next instruction register
    output logic zr,                    // zero detected
    output logic rf_w_mux_jump_next,    // next value of rf_w_mux_jump for next stage
    output logic op_ld_or_ldr_next,     // LD or LDR from this stage
    output logic op_st_next,            // ST from this stage
    input logic op_ld_or_ldr_exec,      // LD or LDR from exec stage
    input logic op_ld_or_ldr_mem,       // LD or LDR from mem access stage
    input logic op_ld_or_ldr_wb,        // LD or LDR from write back stage
    output logic stall,                 // pipeline stall control signal

    // portions of instructions containing register numbers
    input logic [14:0] ir_exec,         // instruction in execute stage
    input logic [14:0] ir_mem,          // instruction in mem access stage
    input logic [14:0] ir_wb,           // instruction in write back stage

    // bypass signals
    input logic [31:0] ex_bypass,       // execution stage bypass
    input logic [31:0] mem_bypass,      // memory access stage bypass
    input logic [31:0] wb_bypass,       // write back stage bypass

    // signals from write back stage
    input logic [4:0] rf_w_addr,        // register file write address
    input logic [31:0] rf_w_data,       // register file write data
    input logic rf_we                   // register file write enable
);

logic [31:0] pc_decode;
logic [31:0] ir_decode;
logic [5:0] opcode;
logic [4:0] ra;
logic [4:0] rb;
logic [4:0] rc;
logic [15:0] constant;

logic op_ld;
logic op;
logic opc;
logic a_sel;
logic b_sel;

logic ra2_sel;
logic [4:0] ra1;
logic [4:0] ra2;
logic [31:0] rd1;
logic [31:0] rd2;

always_comb begin
    opcode = ir_decode[31:26];
    ra = ir_decode[20:16];
    rb = ir_decode[15:11];
    rc = ir_decode[25:21];
    constant = ir_decode[15:0];
    
    zr = ~|rd1;
    j_addr = rd1;

    // set the branch address to PC_decode + 4 + 4 * SXT(C)
    br_addr = pc_decode + {{14{constant[15]}}, constant, 2'b00};

    ///////////////////////////////////////////////////////////////////////////
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
    ///////////////////////////////////////////////////////////////////////////

    opc = opcode[5] && opcode[4];
    op = opcode[5] && !opcode[4];

    op_st_next = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
    op_ld = !opcode[5] && !opcode[2] && !opcode[1] && !opcode[0];
    op_jmp = !opcode[5] && !opcode[2] && opcode[1] && opcode[0];
    op_beq = !opcode[5] && opcode[2] && !opcode[1] && !opcode[0];
    op_bne = !opcode[5] && opcode[2] && !opcode[1] && opcode[0];
    op_ld_or_st = !opcode[5] && !opcode[2] && !opcode[1];
    op_ldr = opcode[0] && opcode[1] && opcode[2];
    op_ld_or_ldr_next = op_ld || op_ldr;

    ra1 = ra;
    ra2_sel = op_st_next;
    ra2 = ra2_sel ? rc : rb;

    a_sel = op_ldr;
    a_next = a_sel ? br_addr : rd1;
    b_sel = op_ld || opc || op_st_next;

    d_next = rd2;

    // B = BSEL ? SXT(C) : RD2
    b_next = b_sel ? {{16{constant[15]}}, constant} : rd2;

    rf_w_mux_jump_next = op_jmp || op_bne || op_beq;

    // mux for the next instruction register in the pipeline
    // case (ir_src_dec)
    //     `IR_SRC_EXCEPT: ir_next = `INST_BNE_EXCEPT;
    //     `IR_SRC_NOP: ir_next = `INST_NOP;
    //     `IR_SRC_DATA: ir_next = ir_decode;
    //     default: ir_next = 'x;
    // endcase
    if (stall) begin
        ir_next = `INST_NOP;
    end else begin
        ir_next = ir_decode;
    end

    pc_next = pc_decode;
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        ir_decode <= `INST_NOP;
    end else if (~stall) begin
        ir_decode <= ir;
        pc_decode <= pc;
    end
end

reg_file rf(
    .clk(clk),
    .rst(rst),

    .ir_decode(ir_decode[25:11]),
    .ir_exec(ir_exec),
    .ir_mem(ir_mem),
    .ir_wb(ir_wb),
    .opcode_type_op(op),

    .op_ld_or_ldr_exec(op_ld_or_ldr_exec),
    .op_ld_or_ldr_mem(op_ld_or_ldr_mem),
    .op_ld_or_ldr_wb(op_ld_or_ldr_wb),
    .op_st(op_st_next),
    .stall(stall),

    .ra1(ra1),
    .ra2(ra2),
    .rd1(rd1),
    .rd2(rd2),
    .we(rf_we),
    .wa(rf_w_addr),
    .wd(rf_w_data),

    .exec_bypass(ex_bypass),
    .mem_bypass(mem_bypass),
    .wb_bypass(wb_bypass)
);

endmodule