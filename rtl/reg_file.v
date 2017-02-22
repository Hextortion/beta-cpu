///////////////////////////////////////////////////////////////////////////////
//  File name: reg_file.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the register file implementation
///////////////////////////////////////////////////////////////////////////////

module reg_file(
    // clock and reset
    input logic clk,                // clock
    input logic rst,                // reset

    // control signals
    input logic [14:0] ir_decode,   // instruction register in decode stage
    input logic [14:0] ir_exec,     // instruction register in execute stage
    input logic [14:0] ir_mem,      // instruction register in mem access stage
    input logic [14:0] ir_wb,       // instruction register in write back stage
    input logic opcode_type_op,     // opcode is of class OP
    input logic op_ld_or_ldr_exec,  // opcode is LD or LDR in exec stage
    input logic op_ld_or_ldr_mem,   // opcode is LD or LDR in mem stage
    input logic op_ld_or_ldr_wb,    // opcode is LD or LDR in wb stage
    input logic op_st,              // opcode is ST
    output logic stall,             // stall control signal

    // datapath signals
    input logic [4:0] ra1,          // read address 1
    input logic [4:0] ra2,          // read address 2
    output logic [31:0] rd1,        // read data 1
    output logic [31:0] rd2,        // read data 2    
    input logic we,                 // write enable
    input logic [4:0] wa,           // write address
    input logic [31:0] wd,          // write data
    input logic [31:0] exec_bypass, // bypass from execute stage
    input logic [31:0] mem_bypass,  // bypass from memory access stage
    input logic [31:0] wb_bypass    // bypass from write back stage
);

logic [31:0] mem[0:31];

logic [31:0] rd1_0;
logic [31:0] rd2_0;

logic check_ra2_hazard;             // Check Rb hazard if ST or opcode type op
logic ra_dec_eq_rc_ex;              // Ra in decode == Rc in exec
logic ra_dec_eq_rc_mem;             // Ra in decode == Rc in memory access
logic ra_dec_eq_rc_wb;              // Ra in decode == Rc in write back
logic rb_dec_eq_rc_ex;              // Rb in decode == Rc in exec
logic rb_dec_eq_rc_mem;             // Rb in decode == Rc in memory access
logic rb_dec_eq_rc_wb;              // Rb in decode == Rc in write back

// This is a hack so that the simulation will work correctly.
// TODO: Figure out how to set all the registers to zero on a reset
initial begin
    for (integer i = 0; i < 32; i++) begin
        mem[i] = 32'd0;
    end
end

always_comb begin
    rd1_0 = mem[ra1];
    rd2_0 = mem[ra2];

    // if we have an ST instruction, then the RA2 input into the register
    // file is actually Rc
    check_ra2_hazard = opcode_type_op || op_st;

    ra_dec_eq_rc_ex = ra1 == ir_exec[14:10];
    ra_dec_eq_rc_mem = ra1 == ir_mem[14:10];
    ra_dec_eq_rc_wb = ra1 == ir_wb[14:10];
    rb_dec_eq_rc_ex = ra2 == ir_exec[14:10];
    rb_dec_eq_rc_mem = ra2 == ir_mem[14:10];
    rb_dec_eq_rc_wb = ra2 == ir_wb[14:10];

    if (rst) begin
        stall = 1'b0;
    end else begin
        stall = op_ld_or_ldr_exec && ra_dec_eq_rc_ex ||
                op_ld_or_ldr_mem && ra_dec_eq_rc_mem ||
                (check_ra2_hazard) && (
                op_ld_or_ldr_exec && rb_dec_eq_rc_ex ||
                op_ld_or_ldr_mem && rb_dec_eq_rc_mem);
    end

    if (ra1 == 5'd31) begin
        rd1 = 32'd0;
    end else if (ra_dec_eq_rc_ex && !op_ld_or_ldr_exec) begin
        rd1 = exec_bypass;
    end else if (ra_dec_eq_rc_mem && !op_ld_or_ldr_mem) begin
        rd1 = mem_bypass;
    end else if (ra_dec_eq_rc_wb) begin
        rd1 = wb_bypass;
    end else if (we && wa == ra1) begin
        rd1 = wd;
    end else begin
        rd1 = rd1_0;
    end

    if (ra2 == 5'd31) begin
        rd2 = 32'd0;
    end else if (rb_dec_eq_rc_ex && !op_ld_or_ldr_exec && check_ra2_hazard) begin
        rd2 = exec_bypass;
    end else if (rb_dec_eq_rc_mem && !op_ld_or_ldr_mem && check_ra2_hazard) begin
        rd2 = mem_bypass;
    end else if (rb_dec_eq_rc_wb && check_ra2_hazard) begin
        rd2 = wb_bypass;
    end else if (we && wa == ra2) begin
        rd2 = wd;
    end else begin
        rd2 = rd2_0;
    end
end

always_ff @(posedge clk) begin
    if (we && wa != 5'd31) begin
        mem[wa] <= wd;
    end
end

endmodule