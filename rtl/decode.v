///////////////////////////////////////////////////////////////////////////////
//  File name: decode.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the implementaion of decode stage
//  TODO: Add bypassing logic
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module decode(
    input logic clk,                    // clock   

    // datapath signals
    input logic [31:0] pc_plus_four,    // PC + 4
    input logic [31:0] inst             // instruction that has been fetched

    output logic [31:0] jump_addr,      // jump target address
    output logic [31:0] branch_addr,    // branch target address
    output logic [31:0] st_data,        // store data for mem access stage

    output logic [31:0] a_reg,          // output for register A in ALU stage
    output logic [31:0] b_reg,          // output for register B in ALU stage

    output logic [31:0] pc_decode,      // pc output for next stage
    output logic [31:0] inst_next,      // instruction output for next stage

    // control signals
    input logic [1:0] ir_src_dec        // source for next instruction register
    output logic zero,                  // zero detected

    // bypass signals
    input logic [31:0] ex_bypass,       // execution stage bypass
    input logic [31:0] mem_bypass,      // memory access stage bypass
    input logic [31:0] wb_bypass,       // write back stage bypass

    // signals from write back stage
    input logic [4:0] rf_w_addr,        // register file write address
    input logic [31:0] rf_w_data,       // register file write data
    input logic rf_we                   // register file write enable
);

logic [31:0] ir_decode;
logic [5:0] opcode;
logic [4:0] ra;
logic [4:0] rb;
logic [4:0] rc;
logic [15:0] constant;

logic op_st;
logic op_ld;
logic op_ldr;
logic op;

logic ra2_sel;
logic [4:0] ra1;
logic [4:0] ra2;
logic [31:0] rd1;
logic [31:0] rd2;

always_comb begin
    ra = ir_decode[20:16];
    rb = ir_decode[15:11];
    rc = ir_decode[25:21];
    constant = ir_decode[15:0];

    ra1 = ra;
    ra2_sel = op_st;
    ra2 = ra2_sel ? rc ? rb;
    
    zero = ~|rd1;
    jump = rd1;

    // set the branch address to PC_decode + 4 + 4 * SXT(C)
    branch_addr = pc_decode + 32'd4 + {14{constant[15]}, constant, 2'b00};

    opc = opcode[5] && opcode[4];
    op_st = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
    op_ld = !opcode[5] && !opcode[2] && !opcode[1] && !opcode[0];
    op_ldr = opcode[0] && opcode[1] && opcode[2];
    a_sel = op_ldr;
    a_reg = a_sel ? branch_addr : rd1;
    b_sel = op_ld || opc || op_st;

    st_data = rd2;

    // B = BSEL ? SXT(C) : RD2
    b_reg = b_sel ? {16{constant[15]}, constant} : rd2;

    // mux for the next instruction register in the pipeline
    case (ir_src_dec)
        IR_SRC_EXCEPT: inst_next = INST_BNE_EXCEPT;
        IR_SRC_NOP: inst_next = INST_NOP;
        IR_SRC_DATA: inst_next = ir_decode;
        default: inst_next = 'x;
    endcase
end

always_ff @(posedge clk) begin
    ir_decode <= inst;
    if (~stall) begin
        pc_decode <= pc_plus_four;
    end
end

reg_file rf(
    .clk(clk),
    .ra1(ra1),
    .ra2(ra2),
    .rd1(rd1),
    .rd2(rd2),
    .we(rf_we),
    .wa(ra_w_addr),
    .wd(rf_w_data)
);

endmodule