///////////////////////////////////////////////////////////////////////////////
//  File name: core_tb.v
//  Author: Stefan Dumitrescu
//  
//  Description: This runs some test cases on the basic core with the memory
//               being simulated.
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`include "defines.v"

module core_tb;

logic clk;
logic rst;

always begin
    clk = 0;
    #10;
    clk = 1;
    #10;
end

logic [31:0] d_mem [0:1023];
logic [31:0] d_mem_w_data;
logic [31:0] d_mem_w_addr;
logic [31:0] d_mem_r_data;
logic [31:0] d_mem_we;
logic [31:0] d_mem_oe;

logic [31:0] i_mem [0:1023];
logic [31:0] i_mem_r_addr;
logic [31:0] i_mem_r_data;

core dut(
    .clk(clk),
    .rst(rst),
    .i_mem_r_data(i_mem_r_data),
    .i_mem_r_addr(i_mem_r_addr),
    .d_mem_w_data(d_mem_w_data),
    .d_mem_w_addr(d_mem_w_addr),
    .d_mem_r_data(d_mem_r_data),
    .d_mem_we(d_mem_we),
    .d_mem_oe(d_mem_oe)
);

// ddd the integers from 1 to 100 and store them in R0
logic [31:0] test_1[6] = '{
    {`OPCODE_ADDC, 5'd0, 5'd31, 16'd0},
    {`OPCODE_ADDC, 5'd1, 5'd31, 16'd100},
    {`OPCODE_ADD, 5'd0, 5'd1, 5'd0, 11'd0},
    {`OPCODE_SUBC, 5'd1, 5'd1, 16'd1},
    {`OPCODE_BNE, 5'd31, 5'd1, -16'd3},
    {`OPCODE_BEQ, 5'd31, 5'd31, -16'd1}
};

logic [31:0] test_2[8] = '{
    {`OPCODE_ADDC, 5'd0, 5'd0, 16'd1},
    {`OPCODE_ADDC, 5'd1, 5'd1, 16'd2},
    {`OPCODE_OR, 5'd2, 5'd1, 5'd0, 11'd0},
    {`OPCODE_ADD, 5'd31, 5'd31, 5'd31, 11'd0},
    {`OPCODE_ADD, 5'd31, 5'd31, 5'd31, 11'd0},
    {`OPCODE_ADD, 5'd31, 5'd31, 5'd31, 11'd0},
    {`OPCODE_ADD, 5'd31, 5'd31, 5'd31, 11'd0},
    {`OPCODE_ADD, 5'd31, 5'd31, 5'd31, 11'd0}
};

// at the end R4 = 1, R5 = -1
logic [31:0] test_3[11] = '{
    {`OPCODE_ADDC, 5'd0, 5'd0, 16'd1},
    {`OPCODE_ADDC, 5'd1, 5'd1, 16'd2},
    {`OPCODE_ADD, 5'd2, 5'd1, 5'd0, 11'd0},
    {`OPCODE_ST, 5'd2, 5'd31, 16'd0},
    {`OPCODE_ST, 5'd1, 5'd31, 16'd4},
    {`OPCODE_ST, 5'd0, 5'd31, 16'd8},
    {`OPCODE_LD, 5'd3, 5'd31, 16'd0},
    {`OPCODE_SUBC, 5'd4, 5'd3, 16'd1},
    {`OPCODE_LD, 5'd4, 5'd31, 16'd8},
    {`OPCODE_SUBC, 5'd5, 5'd4, 16'd2},
    {`OPCODE_BEQ, 5'd31, 5'd31, -16'd1}
};

initial begin
    for (integer i = 0; i < 1024; i++) begin
        i_mem[i] = 32'd0;
        d_mem[i] = 32'd0;
    end

    for (integer i = 0; i < $size(test_1); i++) begin
        i_mem[i] = test_1[i];
    end

    rst = 0;
    @(posedge clk);
    rst = 1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    rst = 0;
end

always_comb begin
    i_mem_r_data = i_mem[i_mem_r_addr[11:2]];
    d_mem_r_data = d_mem[d_mem_w_addr[11:2]];
end

always_ff @(posedge clk) begin
    if (d_mem_we) begin
        d_mem[d_mem_w_addr[11:2]] <= d_mem_w_data;
    end
end

endmodule