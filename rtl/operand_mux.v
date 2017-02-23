///////////////////////////////////////////////////////////////////////////////
// File name: operand_mux.v
// Author: Stefan Dumitrescu
// 
// Description: This file implements the operand mux
///////////////////////////////////////////////////////////////////////////////

module operand_mux(
    input logic [4:0] ra,                   // read address
    input logic [31:0] rd_in,               // input into rd mux

    input logic [31:0] ex_y_bypass,         // Y bypass from execute stage
    input logic [31:0] ex_pc_bypass,        // PC bypass from execute stage

    input logic [31:0] mem_y_bypass,        // Y bypass from memory access stage
    input logic [31:0] mem_pc_bypass,       // PC bypass from memory access stage

    input logic [31:0] wb_bypass,           // register write value from write back stage

    input logic [4:0] rc_wb,                // Rc from write back stage
    input logic [4:0] rc_mem,               // Rc from memory access stage
    input logic [4:0] rc_ex,                // Rc from execute stage

    input logic op_br_or_jmp_ex,            // instruction is BEQ, BNE, or JMP in execute stage
    input logic op_br_or_jmp_mem,           // instruction is BEQ, BNE, or JMP in memory access stage

    output logic [31:0] rd_out,             // output of the rd mux
    output logic ra_eq_rc_wb,               // Ra = Rc_WB
    output logic ra_eq_rc_mem,              // Ra = Rc_MEM
    output logic ra_eq_rc_ex                // Ra = Rc_EX
);

logic ra_ex_bypass;
logic ra_mem_bypass;
logic ra_wb_bypass; 
logic ra_reg_file;
logic ra_zr;

logic [4:0] operand_sel;

always_comb begin
    ra_eq_rc_wb = rc_wb == ra;
    ra_eq_rc_mem = rc_mem == ra;
    ra_eq_rc_ex = rc_ex == ra;
    ra_zr = 5'd31 == ra;

    ra_ex_bypass = !ra_zr && ra_eq_rc_ex;
    ra_mem_bypass = !ra_zr && !ra_eq_rc_ex && ra_eq_rc_mem;
    ra_wb_bypass = !ra_zr && !ra_eq_rc_ex && !ra_eq_rc_mem && ra_eq_rc_wb;
    ra_reg_file = !ra_zr && !ra_eq_rc_ex && !ra_eq_rc_mem && !ra_eq_rc_wb;

    operand_sel = {ra_reg_file, ra_wb_bypass, ra_mem_bypass, 
                   ra_ex_bypass, ra_zr};

    case (operand_sel)
        5'b10000: rd_out = rd_in;
        5'b01000: rd_out = wb_bypass;
        5'b00100: rd_out = op_br_or_jmp_mem ? mem_pc_bypass : mem_y_bypass;
        5'b00010: rd_out = op_br_or_jmp_ex ? ex_pc_bypass : ex_y_bypass;
        5'b00001: rd_out = 32'd0;
        default: rd_out = 'x;
    endcase
end

endmodule