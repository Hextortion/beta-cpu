///////////////////////////////////////////////////////////////////////////////
// File name: bypass.v
// Author: Stefan Dumitrescu
// 
// Description: This file implements the bypassing logic
///////////////////////////////////////////////////////////////////////////////

module bypass(
    input logic [4:0] ra1,                  // read address 1 
    input logic [4:0] ra2,                  // read address 2

    input logic [31:0] rd1_in,              // input into rd1 mux
    input logic [31:0] rd2_in,              // input into rd2 mux

    input logic [31:0] ex_y_bypass,         // Y bypass from execute stage
    input logic [31:0] ex_pc_bypass,        // PC bypass from execute stage

    input logic [31:0] mem_y_bypass,        // Y bypass from memory access stage
    input logic [31:0] mem_pc_bypass,       // PC bypass from memory access stage

    input logic [31:0] wb_bypass,           // register write value from write back stage

    input logic [4:0] rc_wb,                // Rc from write back stage
    input logic [4:0] rc_mem,               // Rc from memory access stage
    input logic [4:0] rc_ex,                // Rc from execute stage

    input logic op_st_wb,                   // instruction is ST in write back stage
    input logic op_st_mem,                  // instruction is ST in memory access stage
    input logic op_st_ex,                   // instruction is ST in execute stage

    input logic op_br_or_jmp_ex,            // instruction is BEQ, BNE, or JMP in execute stage
    input logic op_br_or_jmp_mem,           // instruction is BEQ, BNE, or JMP in memory access stage

    output logic [31:0] rd1_out,            // output of the rd1 mux
    output logic [31:0] rd2_out             // output of the rd2 mux
);

logic [4:0] rc_wb_0;
logic [4:0] rc_mem_0;
logic [4:0] rc_ex_0;

always_comb begin
    // the ST instruction does not write to the register file, so nothing
    // needs to be bypassed
    rc_wb_0 = op_st_wb ? 5'd31 : rc_wb;
    rc_mem_0 = op_st_mem ? 5'd31 : rc_mem;
    rc_ex_0 = op_st_ex ? 5'd31 : rc_ex;
end

operand_mux operand_mux0(
    .ra(ra1),
    .rd_in(rd1_in),
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
    .rd_out(rd1_out)
);

operand_mux operand_mux1(
    .ra(ra2),
    .rd_in(rd2_in),
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
    .rd_out(rd2_out)
);

endmodule