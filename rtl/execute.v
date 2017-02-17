///////////////////////////////////////////////////////////////////////////////
//  File name: execute.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the implementaion of the execute stage
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module execute (
    input clk,                              // clock

    // control signals
    input logic [1:0] ir_src_exec           // instruction register source

    // datapath signals
    input logic [31:0] pc_exec_next,        // next pc value for this stage
    input logic [31:0] ir_exec_next,        // next ir value for this stage
    input logic [31:0] a_exec_next,         // next a value for this stage
    input logic [31:0] b_exec_next,         // next b value for this stage
    input logic [31:0] st_exec_next,        // next st value for this stage

    output logic [31:0] pc_mem_next,        // next pc value for the next stage
    output logic [31:0] ir_mem_next,        // next ir value for the next stage
    output logic [31:0] y_mem_next,         // next y value for the next stage
    output logic [31:0] st_mem_next,        // next st value for the next stage
);

// pipeline registers for the execute stage
logic [31:0] pc_exec;
logic [31:0] ir_exec;
logic [31:0] a_exec;
logic [31:0] b_exec;
logic [31:0] st_exec;

logic [5:0] opcode;
logic [5:0] fn;

always_ff @(posedge clk) begin
    pc_exe <= pc_exec_next;
    ir_exec <= ir_exec_next;
    a_axec <= a_exec_next;
    b_exec <= b_exec_next;
    st_exec <= st_exec_next;
end

always_comb begin
    opcode = ir_exec[31:26];

    case (opcode)
        OPCODE_CMP: begin
            fn[5:4] = ALU_MUX_CMP;
        end

        OPCODE_ARITH: begin
            fn[5:4] = ALU_MUX_ARITH;
            fn[3:1] = 3'bxxx;
            // Last bit decides between add and subtract
            fn[0] = opcode[0] ? 1'b1 : 1'b0;
        end

        OPCODE_BOOL: begin
            fn[1:0] = ALU_MUX_BOOL;
        end

        OPCODE_SHIFT: begin
            fn[1:0] = ALU_MUX_SHIFT;
        end
    endcase

    // mux for the next instruction register in the pipeline
    case (ir_src_exec)
        IR_SRC_EXCEPT: ir_mem_next = INST_BNE_EXCEPT;
        IR_SRC_NOP: ir_mem_next = INST_NOP;
        IR_SRC_DATA: ir_mem_next = ir_decode;
        default: ir_mem_next = 'x;
    endcase
end

alu alu0(
    .fn(),
    .a(a_exec),
    .b(b_exec),
    .y(y_mem_next),
);

endmodule