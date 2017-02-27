///////////////////////////////////////////////////////////////////////////////
// File name: operand_mux.v
// Author: Stefan Dumitrescu
// 
// Description: This file implements the operand mux
///////////////////////////////////////////////////////////////////////////////

module operand_mux(
    input [4:0] ra,                 // read address
    input [31:0] rd_in,             // input into rd mux
    input [31:0] ex_y_bypass,       // Y bypass from execute stage
    input [31:0] ex_pc_bypass,      // PC bypass from execute stage
    input [31:0] mem_y_bypass,      // Y bypass from memory access stage
    input [31:0] mem_pc_bypass,     // PC bypass from memory access stage
    input [31:0] wb_bypass,         // reg write value from write back stage
    input [4:0] rc_wb,              // Rc from write back stage
    input [4:0] rc_mem,             // Rc from memory access stage
    input [4:0] rc_ex,              // Rc from execute stage
    input op_br_or_jmp_ex,          // BEQ, BNE, or JMP in execute stage
    input op_br_or_jmp_mem,         // BEQ, BNE, or JMP in memory access stage
    output reg [31:0] rd_out,       // output of the rd mux
    output ra_eq_rc_wb,             // Ra = Rc_WB
    output ra_eq_rc_mem,            // Ra = Rc_MEM
    output ra_eq_rc_ex              // Ra = Rc_EX
);

wire ra_eq_31;
wire [31:0] ex_bypass;
wire [31:0] mem_bypass;

//
// Note that if the ST instruction is in the mem, wb, or ex stage, then the
// corresponding rc (rc_wb, rc_mem, or rc_ex) will be set to 32. This should
// result in rd_out = rd_in.
//
assign ra_eq_rc_wb = rc_wb == ra;
assign ra_eq_rc_mem = rc_mem == ra;
assign ra_eq_rc_ex = rc_ex == ra;
assign ra_eq_31 = &ra;

assign ex_bypass = op_br_or_jmp_ex ? ex_pc_bypass : ex_y_bypass;
assign mem_bypass = op_br_or_jmp_mem ? mem_pc_bypass : mem_y_bypass;

always @(*) begin
    case ({ra_eq_31, ra_eq_rc_ex, ra_eq_rc_mem, ra_eq_rc_wb})
        4'b0000: rd_out = rd_in;
        4'b0001: rd_out = wb_bypass;
        4'b0010: rd_out = mem_bypass;
        4'b0011: rd_out = mem_bypass;
        4'b0100: rd_out = ex_bypass;
        4'b0101: rd_out = ex_bypass;
        4'b0110: rd_out = ex_bypass;
        4'b0111: rd_out = ex_bypass;
        4'b1000: rd_out = 32'd0;
        4'b1001: rd_out = 32'd0;
        4'b1010: rd_out = 32'd0;
        4'b1011: rd_out = 32'd0;
        4'b1100: rd_out = 32'd0;
        4'b1101: rd_out = 32'd0;
        4'b1110: rd_out = 32'd0;
        4'b1111: rd_out = 32'd0;
    endcase
end

endmodule