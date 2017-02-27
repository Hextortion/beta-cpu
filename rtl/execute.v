///////////////////////////////////////////////////////////////////////////////
// File name: execute.v
// Author: Stefan Dumitrescu
//
// Description: This file contains the implementaion of the execute stage
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module execute(
    input clk,                        // clock

    output op_ld_or_ldr,              // IR is LD or LDR
    output op_st,                     // IR is ST
    output op_br_or_jmp,              // IR is BR or JMP

    // datapath signals
    input [31:0] pc,                  // next pc value for this stage
    input [31:0] ir,                  // next ir value for this stage
    input [31:0] a,                   // next a value for this stage
    input [31:0] b,                   // next b value for this stage
    input [31:0] d,                   // next d value for this stage

    output [31:0] pc_next,            // next pc value for the next stage
    output reg [31:0] ir_next,        // next ir value for the next stage
    output [31:0] y_next,             // next y value for the next stage
    output [31:0] d_next              // next d value for the next stage
);

// pipeline registers for the execute stage
reg [31:0] pc_exec;
reg [31:0] ir_exec;
reg [31:0] a_exec;
reg [31:0] b_exec;
reg [31:0] d_exec;

wire op_ld_or_st;
wire op_ldr;
wire op_ld;
wire op_jmp;
wire op_beq;
wire op_bne;
wire [5:0] opcode;
reg [5:0] fn;

wire preceding_exception;
wire current_exception;

assign pc_next = pc_exec;
assign d_next = d_exec;

always @(posedge clk) begin
    pc_exec <= pc;
    ir_exec <= ir;
    a_exec <= a;
    b_exec <= b;
    d_exec <= d;
end

///////////////////////////////////////////////////////////////////////////////
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
///////////////////////////////////////////////////////////////////////////////

assign opcode = ir_exec[31:26];
assign op_st = !opcode[5] && !opcode[2] && !opcode[1] && opcode[0];
assign op_ld = !opcode[5] && !opcode[2] && !opcode[1] && !opcode[0];
assign op_jmp = !opcode[5] && !opcode[2] && opcode[1] && opcode[0];
assign op_beq = !opcode[5] && opcode[2] && !opcode[1] && !opcode[0];
assign op_bne = !opcode[5] && opcode[2] && !opcode[1] && opcode[0];
assign op_br_or_jmp = op_jmp | op_bne | op_beq;
assign op_ld_or_st = !opcode[5] && !opcode[2] && !opcode[1];
assign op_ldr = opcode[0] && opcode[1] && opcode[2];
assign op_ld_or_ldr = op_ldr || op_ld;

always @(*) begin
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
                    default: fn[2:1] = 2'bx;
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
                    default: fn[2:1] = 2'bx;
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
            fn = 6'bx;
        end
    end
end

assign preceding_exception = 1'b0;
assign current_exception = 1'b0;

always @(*) begin
    if (preceding_exception) begin
        ir_next = `INST_NOP;
    end else begin
        if (current_exception) begin
            ir_next = `INST_BNE_EXCEPT;
        end else begin
            ir_next = ir_exec;
        end
    end
end

alu alu0(
    .fn(fn),
    .a(a_exec),
    .b(b_exec),
    .y(y_next)
);

endmodule