///////////////////////////////////////////////////////////////////////////////
//  File name: decode.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the implementaion of decode stage
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module decode(
    input logic clk,                    // clock   

    // datapath signals
    input logic [31:0] pc_plus_four,    // PC + 4
    input logic [31:0] inst             // instruction that has been fetched

    output logic [31:0] jump_addr,      // jump target address
    output logic [31:0] branch_addr,    // branch target address

    // bypass signals
    input logic [31:0] ex_bypass,       // execution stage bypass
    input logic [31:0] mem_bypass,      // memory access stage bypass
    input logic [31:0] wb_bypass,       // write back stage bypass

    // signals from write back stage
    input logic [5:0] rf_w_addr,        // register file write address
    input logic [31:0] rf_w_data,       // register file write data
    input logic rf_we                   // register file write enable
);

endmodule