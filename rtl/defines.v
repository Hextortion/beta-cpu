///////////////////////////////////////////////////////////////////////////////
//  File name: defines.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains constants used throughout the project
///////////////////////////////////////////////////////////////////////////////

// instructions
`define INST_BNE_EXCEPT 32'hcfdf0000            // BNE(R31, 0, XP)
`define INST_NOP 32'h83fff800                   // ADD(R31, R31, R31)

// pc default addresses
`define PC_RESET_ADDR 32'h80000000
`define PC_EXCEPT_ADDR 32'h80000004
`define PC_ILLOP_ADDR 32'h80000008

// instruction register source control signal
`define IR_SRC_EXCEPT 2'd0
`define IR_SRC_NOP 2'd1
`define IR_SRC_DATA 2'd2

// opcode types
`define OPCODE_CMP 6'b1x01xx
`define OPCODE_ARITH 6'b1x00xx
`define OPCODE_BOOL 6'b1x10xx
`define OPCODE_SHIFT 6'b1x11xx

// ALU defines
`define ALU_MUX_CMP 2'b00;
`define ALU_MUX_ARITH 2'b01;
`define ALU_MUX_BOOL 2'b10;
`define ALU_MUX_SHIFT 2'b11;