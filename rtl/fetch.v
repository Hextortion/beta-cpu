///////////////////////////////////////////////////////////////////////////////
//  File name: fetch.v
//  Author: Stefan Dumitrescu
//  
//  Description: Instruction fetch stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module fetch(
    // clock and reset
    input logic clk,                    // clock
    input logic rst,                    // reset

    // control signals
    input logic stall,                  // pipeline stall
    input logic zr,                     // zero
    input logic irq,                    // interrupt line
    input logic ill_op,                 // illegal operation control signal
    input logic op_jmp,                 // JMP control signal
    input logic op_beq,                 // BEQ control signal
    input logic op_bne,                 // BNE control signal

    // datapath signals
    input logic [31:0] br_addr,         // branch target address
    input logic [31:0] j_addr,          // jump target address

    input logic [31:0] i_mem_data,      // instruction memory data
    output logic [31:0] i_mem_addr,     // instruction memory address

    output logic [31:0] pc_next,        // next pc value for next stage
    output logic [31:0] ir_next         // next ir value for next stage
);

logic [31:0] pc_fetch;
logic [31:0] pc_fetch_next;
logic [31:0] pc_plus_four;

logic branch_taken;
logic current_exception;
logic preceding_exception;

always_comb begin
    pc_plus_four = pc_fetch + 32'd4;
    pc_next = pc_plus_four;
    i_mem_addr = pc_fetch;

    // next program counter mux
    case ({irq, ill_op, op_jmp, op_beq, op_bne}) inside
        5'b1xxxx: pc_fetch_next = `PC_EXCEPT_ADDR;
        5'b01xxx: pc_fetch_next = `PC_ILLOP_ADDR;
        5'b00100: pc_fetch_next = j_addr;
        5'b00010: pc_fetch_next = zr ? br_addr : pc_plus_four;
        5'b00001: pc_fetch_next = zr ? pc_plus_four : br_addr;
        5'b00000: pc_fetch_next = pc_plus_four;
        default: pc_fetch_next = 'x;
    endcase

    branch_taken = op_jmp || (op_beq && zr) || (op_bne && !zr);
    preceding_exception = 1'b0;
    current_exception = 1'b0;

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

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        pc_fetch <= `PC_RESET_ADDR;
    end else begin
        if (~stall) begin
            pc_fetch <= pc_fetch_next;
        end
    end
end

endmodule