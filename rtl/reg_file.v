///////////////////////////////////////////////////////////////////////////////
//  File name: reg_file.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the register file implementation
///////////////////////////////////////////////////////////////////////////////

module reg_file(
    input logic clk,                // clock

    // control signals
    input logic [14:0] ir_decode    // instruction register in decode stage
    input logic [14:0] ir_exec      // instruction register in execute stage
    input logic [14:0] ir_mem       // instruction register in mem access stage
    input logic [14:0] ir_wb        // instruction register in write back stage
    logic opcode_type_op,           // opcode is of class OP
    logic opcode_ld_ldr,            // opcode is LD or LDR

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

logic ra_dec_eq_rc_ex,              // Ra in decode == Rc in exec
logic ra_dec_eq_rc_mem,             // Ra in decode == Rc in memory access
logic ra_dec_eq_rc_wb,              // Ra in decode == Rc in write back
logic rb_dec_eq_rc_ex,              // Rb in decode == Rc in exec
logic rb_dec_eq_rc_mem,             // Rb in decode == Rc in memory access
logic rb_dec_eq_rc_wb,              // Rb in decode == Rc in write back
            
always_comb begin
    rd1_0 = mem[ra1];
    rd2_0 = mem[ra2];

    ra_dec_eq_rc_ex = ir_decode[9:5] == ir_exec[14:10];
    ra_dec_eq_rc_mem = ir_decode[9:5] == ir_mem[14:10];
    ra_dec_eq_rc_wb = ir_decode[9:5] == ir_wb[14:10];
    rb_dec_eq_rc_ex = ir_decode[4:0] == ir_exec[14:10];
    rb_dec_eq_rc_mem = ir_decode[4:0] == ir_mem[14:10];
    rb_dec_eq_rc_wb = ir_decode[4:0] == ir_wb[14:10];

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