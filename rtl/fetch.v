///////////////////////////////////////////////////////////////////////////////
//  File name: fetch.v
//  Author: Stefan Dumitrescu
//  
//  Description: Instruction fetch stage of the pipeline
///////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module fetch(
    // clock and reset
    input logic clk,
    input logic reset,

    // control signals
    input logic stall,                  // pipeline stall
    input logic ir_src_rf,              // instruction register source
    input logic [2:0] pc_sel,           // PC select

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

    case (ir_src_rf)
        IR_SRC_EXCEPT: inst = BNE_EXCEPT;
        IR_SRC_NOP: inst = INST_NOP;
        IR_SRC_DATA: inst = imem_data;
        default: inst = 'x;
    endcase

    case (pc_sel)
        PC_SEL_NEXT_PC: pc_next = pc_plus_four;
        PC_SEL_BRANCH: pc_next = branch_addr;
        PC_SEL_JUMP: pc_next = jump_addr;
        PC_SEL_ILLOP: pc_next = PC_ILLOP_ADDR;
        PC_SEL_EXCEPT: pc_next = PC_EXCEPT_ADDR;   
        default: pc_next = 'x;
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        pc <= PC_RESET_ADDR;
    end else begin
        if (~stall) begin
            pc <= pc_next;
        end
    end
end
