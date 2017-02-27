///////////////////////////////////////////////////////////////////////////////
//  File name: execute.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the implementaion of the execute stage
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module execute(
    input logic clk,                        // clock

    output logic op_ld_or_ldr,              // this IR is LD or LDR
    output logic op_st,                     // this IR is ST
    output logic op_br_or_jmp,              // this IR is BR or JMP

    // datapath signals
    input logic [31:0] pc,                  // next pc value for this stage
    input logic [31:0] ir,                  // next ir value for this stage
    input logic [31:0] a,                   // next a value for this stage
    input logic [31:0] b,                   // next b value for this stage
    input logic [31:0] d,                   // next d value for this stage

    output logic [31:0] pc_next,            // next pc value for the next stage
    output logic [31:0] ir_next,            // next ir value for the next stage
    output logic [31:0] y_next,             // next y value for the next stage
    output logic [31:0] d_next              // next d value for the next stage
);

// pipeline registers for the execute stage
logic [31:0] pc_exec;
logic [31:0] ir_exec;
logic [31:0] a_exec;
logic [31:0] b_exec;
logic [31:0] d_exec;

logic op_ld_or_st;
logic op_ldr;
logic op_ld;
logic op_jmp;
logic op_beq;
logic op_bne;
logic [5:0] opcode;
logic [5:0] fn;

logic preceding_exception;
logic current_exception;

always_ff @(posedge clk) begin
    pc_exec <= pc;
    ir_exec <= ir;
    a_exec <= a;
    b_exec <= b;
    d_exec <= d;
end

always_comb begin
    // Opcode Table (columns = opcode[2:0], rows = opcode[5:3])
    //     | 000  | 001  | 010  | 011   | 100    | 101    | 110    | 111 |
    // 000 |      |      |      |       |        |        |        |     |
    // 001 |      |      |      |       |        |        |        |     |
    // 010 |      |      |      |       |        |        |        |     |
    // 011 | LD   | ST   |      | JMP   | BEQ    | BNE    |        | LDR |
    // 100 | ADD  | SUB  |      |       | CMPEQ  | CMPLT  | CMPLE  |     |
    // 101 | AND  | OR   | XOR  | XNOR  | SHL    | SHR    | SRA    |     |
    // 110 | ADDC | SUBC |      |       | CMPEQC | CMPLTC | CMPLEC |     |
    // 111 | ANDC | ORC  | XORC | XNORC | SHLC   | SHRC   | SRAC   |     |
    opcode = ir_exec[31:26];
    op_st = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
    op_ld = !opcode[5] && !opcode[2] && !opcode[1] && !opcode[0];
    op_jmp = !opcode[5] && !opcode[2] && opcode[1] && opcode[0];
    op_beq = !opcode[5] && opcode[2] && !opcode[1] && !opcode[0];
    op_bne = !opcode[5] && opcode[2] && !opcode[1] && opcode[0];
    op_br_or_jmp = op_jmp | op_bne | op_beq;
    op_ld_or_st = !opcode[5] && !opcode[2] && !opcode[1];
    op_ldr = opcode[0] && opcode[1] && opcode[2];
    op_ld_or_ldr = op_ldr || op_ld;

    // generating the correct fn bits for the ALU
    if (opcode[5]) begin
        case (opcode[3:2])
            ///////////////////////////////////////////////////////////////////
            // Opcode Type CMP
            // FN[5:0]      Operation           Output Value Y[31:0]
            // 00x011       CMPEQ               Y = (A == B)
            // 00x101       CMPLT               Y = (A < B)
            // 00x111       CMPLE               Y = (A <= B)
            ///////////////////////////////////////////////////////////////////
            2'b01: begin
                fn[5:4] = `ALU_MUX_CMP;

                case ({opcode[1], opcode[0]})
                    2'b00: fn[2:1] = 2'b01;     // CMPEQ
                    2'b01: fn[2:1] = 2'b10;     // CMPLT
                    2'b10: fn[2:1] = 2'b11;     // CMPLE
                    default: fn[2:1] = 'x;
                endcase

                fn[3] = 1'b0;

                // need the ALU to compute A - B for CMP to work correctly
                fn[0] = 1'b1;
            end

            ///////////////////////////////////////////////////////////////////
            // Opcode Type ADD / SUB
            // FN[5:0]      operation           output value Y[31:0]
            // 01xxx0       32-bit ADD          Y = A + B
            // 01xxx1       32-bit SUBTRACT     Y = A - B
            ///////////////////////////////////////////////////////////////////
            2'b00: begin
                fn[5:4] = `ALU_MUX_ARITH;
                fn[3:1] = 3'b000;

                // last bit decides between add and subtract
                fn[0] = opcode[0] ? 1'b1 : 1'b0;
            end

            ///////////////////////////////////////////////////////////////////
            // Opcode Type BOOL
            // FN[5:0]      operation           output value Y[31:0]
            // 10abcd       bit-wise boolean    Y[i] = F_abcd(A[i], B[i])
            ///////////////////////////////////////////////////////////////////
            2'b10: begin
                fn[5:4] = `ALU_MUX_BOOL;

                case ({opcode[1], opcode[0]})
                    2'b00: fn[3:0] = 4'b1000;     // AND
                    2'b01: fn[3:0] = 4'b1110;     // OR
                    2'b10: fn[3:0] = 4'b0110;     // XOR
                    2'b11: fn[3:0] = 4'b1001;     // XNOR
                endcase
            end

            ///////////////////////////////////////////////////////////////////
            // Opcode Type SHIFT
            // FN[5:0]      operation           output value Y[31:0]
            // 11xx00       Logical shift left  Y = A << B
            // 11xx01       logical shift right Y = A >> B
            // 11xx11       arith shift right   Y = A >> B (sign extended)
            ///////////////////////////////////////////////////////////////////
            2'b11: begin
                fn[5:4] = `ALU_MUX_SHIFT;
                fn[3:2] = 2'b00;

                case ({opcode[1], opcode[0]})
                    2'b00: fn[2:1] = 2'b00;     // SHL
                    2'b01: fn[2:1] = 2'b01;     // SHR
                    2'b10: fn[2:1] = 2'b11;     // SRA
                    default: fn[2:1] = 'x;
                endcase
            end
        endcase
    end else begin
        if (op_ld_or_st) begin
            fn[5:4] = `ALU_MUX_ARITH;
            fn[3:1] = 3'b000;
            fn[0] = 1'b0;
        end else if (op_ldr) begin
            fn[5:4] = `ALU_MUX_BOOL;
            fn[3:0] = 4'b1010;
        end else begin
            fn = 'x;
        end
    end

    preceding_exception = 1'b0;
    current_exception = 1'b0;

    if (preceding_exception) begin
        ir_next = `INST_NOP;
    end else begin
        if (current_exception) begin
            ir_next = `INST_BNE_EXCEPT;
        end else begin
            ir_next = ir_exec;
        end
    end

    pc_next = pc_exec;
    d_next = d_exec;
end

alu alu0(
    .fn(fn),
    .a(a_exec),
    .b(b_exec),
    .y(y_next)
);

endmodule