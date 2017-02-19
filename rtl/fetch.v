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
    input logic zero,                   // zero
    input logic irq,                    // interrupt line
    input logic [1:0] ir_src_rf,        // instruction register source
    input logic ill_op,                 // illegal operation control signal
    input logic op_jmp,                 // JMP control signal
    input logic op_beq,                 // BEQ control signal
    input logic op_bne,                 // BNE control signal

    // datapath signals
    input logic [31:0] branch_addr,     // branch target address
    input logic [31:0] jump_addr,       // jump target address

    input logic [31:0] imem_data,       // instruction memory data
    output logic [31:0] imem_addr       // instruction memory address

    output logic [31:0] pc_plus_four,   // PC + 4
    output logic [31:0] inst            // fetched instruction
);

logic [31:0] pc;
logic [31:0] pc_next;

always_comb begin
    pc_plus_four = pc + 32'd4;
    imem_addr = pc;

    // next program counter mux
    case ({irq, ill_op, op_jmp, op_beq, op_bne}) inside
        5'b1xxxx: pc_next = `PC_EXCEPT_ADDR;
        5'b01xxx: pc_next = `PC_ILLOP_ADDR;
        5'b00100: pc_next = jump_addr;
        5'b00010: pc_next = zero ? branch_addr : pc_plus_four;
        5'b00001: pc_next = zero ? pc_plus_four : branch_addr;
        5'b00000: pc_next = pc_plus_four;
        default: pc_next = 'x;    
    endcase

    // instruction register mux
    case (ir_src_rf)
        `IR_SRC_EXCEPT: inst = `INST_BNE_EXCEPT;
        `IR_SRC_NOP: inst = `INST_NOP;
        `IR_SRC_DATA: inst = imem_data;
        default: inst = 'x;
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        pc <= `PC_RESET_ADDR;
    end else begin
        if (~stall) begin
            pc <= pc_next;
        end
    end
end
