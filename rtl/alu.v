module alu(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [5:0] fn,
    output logic [31:0] y
);

// boolean functions
logic [31:0] bool;
logic [3:0] bool_fn;
always_comb begin
    bool_fn = fn[3:0];
    for (integer i = 0; i < 32; i = i + 1) begin
        case ({b[i], a[i]})
            2'b00: bool[i] = bool_fn[0];
            2'b01: bool[i] = bool_fn[1];
            2'b10: bool[i] = bool_fn[2];
            2'b11: bool[i] = bool_fn[3];
        endcase
    end
end

// shifter
logic [31:0] shift;
logic [1:0] shift_sel;
logic [4:0] shift_amount;
always_comb begin
    shift_sel = fn[1:0];
    shift_amount = b[4:0];
    case (shift_sel)
        2'b00: shift = a << shift_amount;
        2'b01: shift = a >> shift_amount;
        2'b11: shift = $signed(a) >>> shift_amount;
        default: shift = 'x;
    endcase
end

// addition and subtraction unit
logic afn, arith_ov, arith_ng, arith_zr;
logic [31:0] b_ng, arith;
always_comb begin
    afn = fn[0];
    b_ng = afn ? ~b : b;
    arith = a + b_ng + afn;
    arith_ov = a[31] && b_ng[31] && !arith[31] || 
               !a[31] && b_ng[31] && arith[31];
    arith_ng = arith[31];
    arith_zr = ~|arith;
end

// comparison unit
logic [1:0] cmp_sel;
logic lsb;
logic [31:0] cmp;
always_comb begin
    cmp_sel = fn[1:0];
    case (cmp_sel)
        2'b01: lsb = arith_zr;
        2'b10: lsb = arith_ng ^ arith_ov;
        2'b11: lsb = arith_zr | (arith_ng ^ arith_ov);
        default: lsb = 1'bx;
    endcase
    cmp = {31'd0, lsb};
end

// output mux
logic [1:0] y_sel;
always_comb begin
    y_sel = fn[5:4];
    case (y_sel)
        2'b00: y = cmp;
        2'b01: y = arith;
        2'b10: y = bool;
        2'b11: y = shift;
    endcase
end

endmodule