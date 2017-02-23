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
    output logic [31:0] d_next,         // store data for mem access stage
    output logic [31:0] a_next,         // output for register A in ALU stage
    output logic [31:0] b_next,         // output for register B in ALU stage
    output logic [31:0] pc_next,        // pc output for next stage
    output logic [31:0] ir_next,        // instruction output for next stage

    // control signals for the instruction fetch stage
    output logic op_ill,                // illegal opcode
    output logic op_jmp,                // JMP control signal
    output logic op_beq,                // BEQ control signal
    output logic op_bne,                // BNE control signal
    output logic zr,                    // zero detected
    output logic [31:0] j_addr,         // jump target address
    output logic [31:0] br_addr,        // branch target address
    output logic stall,                 // pipeline stall control signal

    // control signals for the stall logic
    input logic op_ld_or_ldr_ex,        // LD or LDR from exec stage
    input logic op_ld_or_ldr_mem,       // LD or LDR from mem access stage

    // control signals for the forwarding unit
    input logic op_br_or_jmp_ex,        // BEQ, BNE, or JMP from exec stage
    input logic op_br_or_jmp_mem,       // BEQ, BNE, or JMP from mem stage
    input logic op_st_ex,               // ST from execute stage
    input logic op_st_mem,              // ST from mem access stage
    input logic op_st_wb,               // ST from write back stage

    // portions of instructions containing Rc
    input logic [4:0] rc_ex,            // Rc in execute stage
    input logic [4:0] rc_mem,           // Rc in mem access stage
    input logic [4:0] rc_wb,            // Rc in write back stage

    // bypass signals
    input logic [31:0] ex_y_bypass,     // execution stage Y bypass
    input logic [31:0] ex_pc_bypass,    // execution stage PC bypass
    input logic [31:0] mem_y_bypass,    // memory access stage Y bypass
    input logic [31:0] mem_pc_bypass,   // memory access stage PC bypas
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
logic [15:0] literal;

logic op_ld;
logic op_ldr;
logic op_st;
logic op_no_lit;                        // opcode does not contain literal
logic op_lit;                           // opcode contains literal
logic a_sel;
logic b_sel;

logic [4:0] ra1;
logic [4:0] ra2;
logic [31:0] rd1_rf_out;
logic [31:0] rd2_rf_out;
logic [31:0] rd1_bypass_out;
logic [31:0] rd2_bypass_out;

logic [4:0] rc_wb_0;
logic [4:0] rc_mem_0;
logic [4:0] rc_ex_0;

logic ra1_eq_rc_wb;
logic ra1_eq_rc_mem;
logic ra1_eq_rc_ex;
logic ra2_eq_rc_wb;
logic ra2_eq_rc_mem;
logic ra2_eq_rc_ex;

logic current_exception;
logic preceding_exception;

always_comb begin
    // the ST instruction does not write to the register file, so nothing
    // needs to be bypassed
    rc_wb_0 = op_st_wb ? 5'd31 : rc_wb;
    rc_mem_0 = op_st_mem ? 5'd31 : rc_mem;
    rc_ex_0 = op_st_ex ? 5'd31 : rc_ex;
end

always_comb begin
    opcode = ir_decode[31:26];
    ra = ir_decode[20:16];
    rb = ir_decode[15:11];
    rc = ir_decode[25:21];
    literal = ir_decode[15:0];
    
    zr = ~|rd1_bypass_out;
    j_addr = rd1_bypass_out;

    // set the branch address to PC_decode + 4 * SXT(literal)
    br_addr = pc_decode + {{14{literal[15]}}, literal, 2'b00};

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

    op_lit = opcode[5] && opcode[4];
    op_no_lit = opcode[5] && !opcode[4];

    op_st = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
    op_ld = !opcode[5] && !opcode[2] && !opcode[1] && !opcode[0];
    op_jmp = !opcode[5] && !opcode[2] && opcode[1] && opcode[0];
    op_beq = !opcode[5] && opcode[2] && !opcode[1] && !opcode[0];
    op_bne = !opcode[5] && opcode[2] && !opcode[1] && opcode[0];
    op_ldr = opcode[0] && opcode[1] && opcode[2];

    ra1 = ra;
    ra2 = op_st ? rc : rb;

    a_next = op_ldr ? br_addr : rd1_bypass_out;

    // B = BSEL ? SXT(C) : RD2
    b_sel = op_ld || op_no_lit || op_st;
    b_next = b_sel ? {{16{literal[15]}}, literal} : rd2_bypass_out;

    d_next = rd2_bypass_out;

    // rf_w_mux_jump_next = op_jmp || op_bne || op_beq;

    if (rst) begin
        stall = 1'b0;
    end else begin
        // stall will be high for a load before use hazard
        stall = op_ld_or_ldr_ex && ra1_eq_rc_ex ||
                op_ld_or_ldr_mem && ra1_eq_rc_mem ||
                (op_no_lit || op_st) && (
                op_ld_or_ldr_ex && ra2_eq_rc_ex ||
                op_ld_or_ldr_mem && ra2_eq_rc_mem);
    end

    preceding_exception = 1'b0;
    current_exception = 1'b0;

    if (!preceding_exception && !current_exception && stall ||
        preceding_exception) begin
        ir_next = `INST_NOP;
    end else begin
        if (current_exception) begin
            ir_next = `INST_BNE_EXCEPT;
        end else begin
            ir_next = ir_decode;
        end
    end

    pc_next = pc_decode;
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        ir_decode <= `INST_NOP;
    end else begin
        if (~stall) begin
            ir_decode <= ir;
            pc_decode <= pc;
        end
    end
end

reg_file rf(
    .clk(clk),
    .ra1(ra1),
    .ra2(ra2),
    .rd1(rd1_rf_out),
    .rd2(rd2_rf_out),
    .we(rf_we),
    .wa(rf_w_addr),
    .wd(rf_w_data)
);

operand_mux operand_mux0(
    .ra(ra1),
    .rd_in(rd1_bypass_out),
    .ex_y_bypass(ex_y_bypass),
    .ex_pc_bypass(ex_pc_bypass),
    .mem_y_bypass(mem_y_bypass),
    .mem_pc_bypass(mem_pc_bypass),
    .wb_bypass(wb_bypass),
    .rc_wb(rc_wb_0),
    .rc_mem(rc_mem_0),
    .rc_ex(rc_ex_0),
    .op_br_or_jmp_ex(op_br_or_jmp_ex),
    .op_br_or_jmp_mem(op_br_or_jmp_mem),
    .rd_out(rd1_bypass_out),
    .ra_eq_rc_wb(ra1_eq_rc_wb),
    .ra_eq_rc_mem(ra1_eq_rc_mem),
    .ra_eq_rc_ex(ra1_eq_rc_ex)
);

operand_mux operand_mux1(
    .ra(ra2),
    .rd_in(rd2_rf_out),
    .ex_y_bypass(ex_y_bypass),
    .ex_pc_bypass(ex_pc_bypass),
    .mem_y_bypass(mem_y_bypass),
    .mem_pc_bypass(mem_pc_bypass),
    .wb_bypass(wb_bypass),
    .rc_wb(rc_wb_0),
    .rc_mem(rc_mem_0),
    .rc_ex(rc_ex_0),
    .op_br_or_jmp_ex(op_br_or_jmp_ex),
    .op_br_or_jmp_mem(op_br_or_jmp_mem),
    .rd_out(rd2_bypass_out),
    .ra_eq_rc_wb(ra2_eq_rc_wb),
    .ra_eq_rc_mem(ra2_eq_rc_mem),
    .ra_eq_rc_ex(ra2_eq_rc_ex)
);

endmodule