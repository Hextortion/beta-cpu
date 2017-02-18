///////////////////////////////////////////////////////////////////////////////
//  File name: execute.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the implementaion of the execute stage
//  TODO: Some of the combinational logic is pretty confusing. See if it can
//        be improved.
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module execute(
    input logic clk,                        // clock

    // control signals
    input logic [1:0] ir_src_exec,          // instruction register source

    // datapath signals
    input logic [31:0] pc_exec_next,        // next pc value for this stage
    input logic [31:0] ir_exec_next,        // next ir value for this stage
    input logic [31:0] a_exec_next,         // next a value for this stage
    input logic [31:0] b_exec_next,         // next b value for this stage
    input logic [31:0] st_exec_next,        // next st value for this stage

    output logic [31:0] pc_mem_next,        // next pc value for the next stage
    output logic [31:0] ir_mem_next,        // next ir value for the next stage
    output logic [31:0] y_mem_next,         // next y value for the next stage
    output logic [31:0] st_mem_next         // next st value for the next stage
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
    pc_exec <= pc_exec_next;
    ir_exec <= ir_exec_next;
    a_exec <= a_exec_next;
    b_exec <= b_exec_next;
    st_exec <= st_exec_next;
end

always_comb begin
    opcode = ir_exec[31:26];

    // generating the correct fn bits for the ALU
    case (opcode)
        ///////////////////////////////////////////////////////////////////////
        // FN[5:0]      Operation           Output Value Y[31:0]
        // 00x011       CMPEQ               Y = (A == B)
        // 00x101       CMPLT               Y = (A < B)
        // 00x111       CMPLE               Y = (A <= B)
        ///////////////////////////////////////////////////////////////////////
        `OPCODE_TYPE_CMP: begin
            fn[5:4] = `ALU_MUX_CMP;

            case ({opcode[1], opcode[0]})
                2'b00: fn[2:1] = 2'b01;     // CMPEQ
                2'b01: fn[2:1] = 2'b10;     // CMPLT
                2'b10: fn[2:1] = 2'b11;     // CMPLE
                default: fn[2:1] = 'x;
            endcase

            fn[3] = 1'bx;

            // need the ALU to compute A - B for CMP to work correctly
            fn[0] = 1'b1;
        end

        ///////////////////////////////////////////////////////////////////////
        // FN[5:0]      operation           output value Y[31:0]
        // 01xxx0       32-bit ADD          Y = A + B
        // 01xxx1       32-bit SUBTRACT     Y = A - B
        ///////////////////////////////////////////////////////////////////////
        `OPCODE_TYPE_ARITH: begin
            fn[5:4] = `ALU_MUX_ARITH;
            fn[3:1] = 3'bxxx;

            // last bit decides between add and subtract
            fn[0] = opcode[0] ? 1'b1 : 1'b0;
        end

        ///////////////////////////////////////////////////////////////////////
        // FN[5:0]      operation           output value Y[31:0]
        // 10abcd       bit-wise boolean    Y[i] = F_abcd(A[i], B[i])
        ///////////////////////////////////////////////////////////////////////
        `OPCODE_TYPE_BOOL: begin
            fn[1:0] = `ALU_MUX_BOOL;

            case ({opcode[1], opcode[0]})
                2'b00: fn[3:0] = 4'b1000;     // AND
                2'b01: fn[3:0] = 4'b1110;     // OR
                2'b10: fn[3:0] = 4'b0110;     // XOR
                2'b11: fn[3:0] = 4'b1001;     // XNOR
            endcase
        end

        ///////////////////////////////////////////////////////////////////////
        // FN[5:0]      operation           output value Y[31:0]
        // 11xx00       Logical shift left  Y = A << B
        // 11xx01       logical shift right Y = A >> B
        // 11xx11       arith shift right   Y = A >> B (sign extended)
        ///////////////////////////////////////////////////////////////////////
        `OPCODE_TYPE_SHIFT: begin
            fn[1:0] = `ALU_MUX_SHIFT;

            case ({opcode[1], opcode[0]})
                2'b00: fn[2:1] = 2'b00;     // SHL
                2'b01: fn[2:1] = 2'b01;     // SHR
                2'b10: fn[2:1] = 2'b11;     // SRA
                default: fn[2:1] = 'x;
            endcase
        end

        `OPCODE_TYPE_LDST: begin
            fn[5:4] = `ALU_MUX_ARITH;
            fn[3:1] = 3'bxxx;
            fn[0] = 1'b0;
        end

        `OPCODE_TYPE_LDR: begin
            fn[5:4] = `ALU_MUX_BOOL;
            fn[3:0] = 4'b1010;
        end

        default: fn = 'x;
    endcase

    // mux for the next instruction register in the pipeline
    case (ir_src_exec)
        `IR_SRC_EXCEPT: ir_mem_next = `INST_BNE_EXCEPT;
        `IR_SRC_NOP: ir_mem_next = `INST_NOP;
        `IR_SRC_DATA: ir_mem_next = ir_exec;
        default: ir_mem_next = 'x;
    endcase
end

alu alu0(
    .fn(fn),
    .a(a_exec),
    .b(b_exec),
    .y(y_mem_next)
);

endmodule