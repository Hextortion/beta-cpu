///////////////////////////////////////////////////////////////////////////////
// File name: alu.v
// Author: Stefan Dumitrescu
//
// Description: This file contains the implementaion of the arithmetic
//              logic unit
///////////////////////////////////////////////////////////////////////////////

module alu(
    // control signals
    input [5:0] fn,               // function to perform

    // datapath signals
    input [31:0] a,               // first operand
    input [31:0] b,               // second operand
    output reg [31:0] y               // result
);

reg [31:0] bool;
wire [3:0] bool_fn;
reg [31:0] shift;
wire [1:0] shift_sel;
wire [4:0] shift_amount;
wire afn; 
wire arith_ov; 
wire arith_ng; 
wire arith_zr;
wire [31:0] b_ng; 
wire [31:0] arith;
wire [1:0] cmp_sel;
reg lsb;
wire [31:0] cmp;
wire [1:0] y_sel;

assign bool_fn = fn[3:0];

assign shift_sel = fn[1:0];
assign shift_amount = b[4:0];

assign afn = fn[0];
assign b_ng = afn ? ~b : b;
assign arith = a + b_ng + afn;
assign arith_ov = a[31] && b_ng[31] && !arith[31] || 
                  !a[31] && !b_ng[31] && arith[31];
assign arith_ng = arith[31];
assign arith_zr = ~|arith;

assign cmp = {31'd0, lsb};
assign cmp_sel = fn[2:1];

assign y_sel = fn[5:4];

integer i;
always @(*) begin
    for (i = 0; i < 32; i = i + 1) begin
        case ({b[i], a[i]})
            2'b00: bool[i] = bool_fn[0];
            2'b01: bool[i] = bool_fn[1];
            2'b10: bool[i] = bool_fn[2];
            2'b11: bool[i] = bool_fn[3];
        endcase
    end
end

always @(*) begin
    case (shift_sel)
        2'b00: shift = a << shift_amount;
        2'b01: shift = a >> shift_amount;
        2'b11: shift = $signed(a) >>> shift_amount;
        default: shift = 32'bx;
    endcase
end

always @(*) begin
    case (cmp_sel)
        2'b01: lsb = arith_zr;
        2'b10: lsb = arith_ng ^ arith_ov;
        2'b11: lsb = arith_zr | (arith_ng ^ arith_ov);
        default: lsb = 1'bx;
    endcase    
end

always @(*) begin
    case (y_sel)
        2'b00: y = cmp;
        2'b01: y = arith;
        2'b10: y = bool;
        2'b11: y = shift;
    endcase
end

endmodule