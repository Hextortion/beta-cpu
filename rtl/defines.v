///////////////////////////////////////////////////////////////////////////////
//  File name: defines.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains constants used throughout the project
///////////////////////////////////////////////////////////////////////////////

`ifndef DEFINES_V
`define DEFINES_V

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

// opcodes
`define OPCODE_LD 6'b011000
`define OPCODE_ST 6'b011001
`define OPCODE_JMP 6'b011011
`define OPCODE_BEQ 6'b011100
`define OPCODE_BNE 6'b011101
`define OPCODE_LDR 6'b011111
`define OPCODE_ADD 6'b100000
`define OPCODE_SUB 6'b100001
`define OPCODE_CMPEQ 6'b100100
`define OPCODE_CMPLT 6'b100101
`define OPCODE_CMPLE 6'b100110
`define OPCODE_AND 6'b101000
`define OPCODE_OR 6'b101001
`define OPCODE_XOR 6'b101010
`define OPCODE_XNOR 6'b101011
`define OPCODE_SHL 6'b101100
`define OPCODE_SHR 6'b101101
`define OPCODE_SRA 6'b101110
`define OPCODE_ADDC 6'b110000
`define OPCODE_SUBC 6'b110001
`define OPCODE_CMPEQC 6'b110100
`define OPCODE_CMPLTC 6'b110101
`define OPCODE_CMPLEC 6'b110110
`define OPCODE_ANDC 6'b111000
`define OPCODE_ORC 6'b111001
`define OPCODE_XORC 6'b111010
`define OPCODE_XNORC 6'b111011
`define OPCODE_SHLC 6'b111100
`define OPCODE_SHRC 6'b111101
`define OPCODE_SRAC 6'b111110

// ALU defines
`define ALU_MUX_CMP 2'b00
`define ALU_MUX_ARITH 2'b01
`define ALU_MUX_BOOL 2'b10
`define ALU_MUX_SHIFT 2'b11

`endif