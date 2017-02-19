///////////////////////////////////////////////////////////////////////////////
//  File name: reg_file.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the register file implementation
///////////////////////////////////////////////////////////////////////////////

module reg_file(
    input logic clk,                // clock

    // control signals
    input logic ra_dec_eq_rc_ex,    // Ra in decode == Rc in exec
    input logic ra_dec_eq_rc_mem,   // Ra in decode == Rc in memory access
    input logic ra_dec_eq_rc_wb,    // Ra in decode == Rc in write back
    input logic rb_dec_eq_rc_ex,    // Rb in decode == Rc in exec
    input logic rb_dec_eq_rc_mem,   // Rb in decode == Rc in memory access
    input logic rb_dec_eq_rc_wb,    // Rb in decode == Rc in write back
    input logic opcode_type_op,     // opcode is of class OP
    input logic opcode_ld_ldr,      // opcode is LD or LDR

    // datapath signals
    input logic [5:0] ra1,          // read address 1
    input logic [5:0] ra2,          // read address 2
    output logic [31:0] rd1,        // read data 1
    output logic [31:0] rd2,        // read data 2    
    input logic we,                 // write enable
    input logic [5:0] wa,           // write address
    input logic [31:0] wd,          // write data
    input logic [31:0] exec_bypass, // bypass from execute stage
    input logic [31:0] mem_bypass,  // bypass from memory access stage
    input logic [31:0] wb_bypass    // bypass from write back stage
);

logic [31:0] mem[0:31];

logic [31:0] rd1_0;
logic [31:0] rd2_0;

always_comb begin
    rd1_0 = mem[ra1];
    rd2_0 = mem[ra2];

    if (ra_dec_eq_rc_ex && !opcode_ld_ldr) begin
        rd1 = exec_bypass;
    end else if (ra_dec_eq_rc_mem && !opcode_ld_ldr) begin
        rd1 = mem_bypass;
    end else if (ra_dec_eq_rc_wb && !opcode_ld_ldr) begin
        rd1 = wb_bypass;
    end else if (we && wa == ra1) begin
        rd1 = wd;
    end else begin
        rd1 = rd1_0;
    end

    if (rb_dec_eq_rc_ex && !opcode_ld_ldr && opcode_type_op) begin
        rd2 = exec_bypass;
    end else if (rb_dec_eq_rc_mem && !opcode_ld_ldr && opcode_type_op) begin
        rd2 = mem_bypass;
    end else if (rb_dec_eq_rc_wb && !opcode_ld_ldr && opcode_type_op) begin
        rd2 = wb_bypass;
    end else if (we && wa == ra2) begin
        rd2 = wd;
    end else begin
        rd2 = rd2_0;
    end
end

always_ff @(posedge clk) begin
    if (we) begin
        mem[wa] <= wd;
    end
end
endmodule