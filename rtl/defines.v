///////////////////////////////////////////////////////////////////////////////
//  File name: defines.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains constants used throughout the project
///////////////////////////////////////////////////////////////////////////////

// pc default addresses
`define PC_RESET_ADDR 32'h80000000
`define PC_EXCEPT_ADDR 32'h80000004
`define PC_ILLOP_ADDR 32'h80000008

// pc select control signal
`define PC_SEL_NEXT_PC 3'd0
`define PC_SEL_BRANCH 3'd1
`define PC_SEL_JUMP 3'd2
`define PC_SEL_ILLOP 3'd3
`define PC_SEL_EXCEPT 3'd4

// instruction register source control signal
`define IR_SRC_EXCEPT 2'd0
`define IR_SRC_NOP 2'd1
`define IR_SRC_DATA 2'd2