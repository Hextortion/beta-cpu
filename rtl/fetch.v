///////////////////////////////////////////////////////////////////////////////
// File name: fetch.v
// Author: Stefan Dumitrescu
//
// Description: Instruction fetch stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module fetch(
    // clock and reset
    input clk,                    // clock
    input rst,                    // reset

    // control signals
    input stall,                  // pipeline stall
    input zr,                     // zero
    input irq,                    // interrupt line
    input op_ill,                 // illegal operation control signal
    input op_jmp,                 // JMP control signal
    input op_beq,                 // BEQ control signal
    input op_bne,                 // BNE control signal

    // datapath signals
    input [31:0] br_addr,         // branch target address
    input [31:0] j_addr,          // jump target address

    input [31:0] i_mem_data,      // instruction memory data
    output [31:0] i_mem_addr,     // instruction memory address

    output [31:0] pc_next,        // next pc value for next stage
    output reg [31:0] ir_next     // next ir value for next stage
);

reg [31:0] pc_fetch;
reg [31:0] pc_fetch_next;
wire [31:0] pc_plus_four;

wire branch_taken;
wire current_exception;
wire preceding_exception;

assign pc_plus_four = pc_fetch + 32'd4;
assign pc_next = pc_plus_four;
assign i_mem_addr = pc_fetch;
assign preceding_exception = 1'b0;
assign current_exception = 1'b0;

always @(*) begin
    if (irq || op_ill || preceding_exception || current_exception) begin
        if (op_ill) begin
            pc_fetch_next = `PC_ILLOP_ADDR;
        end else begin
            pc_fetch_next = `PC_EXCEPT_ADDR;
        end
    end else begin
        case ({op_jmp, op_beq, op_bne})
            3'b100: pc_fetch_next = j_addr;
            3'b010: pc_fetch_next = zr ? br_addr : pc_plus_four;
            3'b001: pc_fetch_next = zr ? pc_plus_four : br_addr;
            3'b000: pc_fetch_next = pc_plus_four;
            default: pc_fetch_next = 32'bx;
        endcase
    end
end

assign branch_taken = op_jmp || (op_beq && zr) || (op_bne && !zr);

always @(*) begin
    if (!preceding_exception && !current_exception &&
        !irq && branch_taken || preceding_exception) begin
        ir_next = `INST_NOP;
    end else begin
        if (current_exception) begin
            ir_next = `INST_BNE_EXCEPT;
        end else begin
            ir_next = i_mem_data;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        pc_fetch <= `PC_RESET_ADDR;
    end else begin
        if (~stall) begin
            pc_fetch <= pc_fetch_next;
        end
    end
end

endmodule