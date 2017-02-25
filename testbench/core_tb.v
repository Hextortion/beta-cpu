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

logic clk = 1'b0;
logic rst;
int cycles = 0;

always begin
    #10 clk = ~clk;
    cycles++;
end

parameter MEM_SIZE = 1024;

logic [31:0] d_mem [0:MEM_SIZE-1];
logic [31:0] d_mem_w_data;
logic [31:0] d_mem_w_addr;
logic [31:0] d_mem_r_data;
logic d_mem_we;
logic d_mem_oe;

logic [31:0] i_mem [0:MEM_SIZE-1];
logic [31:0] i_mem_r_addr;
logic [31:0] i_mem_r_data;

always_comb begin
    i_mem_r_data = i_mem[i_mem_r_addr[11:2]];
    d_mem_r_data = d_mem[d_mem_w_addr[11:2]];
end

always_ff @(posedge clk) begin
    if (d_mem_we) begin
        d_mem[d_mem_w_addr[11:2]] <= d_mem_w_data;
    end
end

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

// add the integers from 1 to 100 and store them in R0
logic [31:0] test1[] = '{
    {`OPCODE_ADDC, 5'd0, 5'd31, 16'd0},
    {`OPCODE_ADDC, 5'd1, 5'd31, 16'd100},
    {`OPCODE_ADD, 5'd0, 5'd1, 5'd0, 11'd0},
    {`OPCODE_SUBC, 5'd1, 5'd1, 16'd1},
    {`OPCODE_BNE, 5'd31, 5'd1, -16'd3},
    {`OPCODE_BEQ, 5'd31, 5'd31, -16'd1}
};

// at the end R1 = 1, R2 = 2, R3 = 3, R4 = 1, R5 = -1
logic [31:0] test2[] = '{
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

task run_test(
    logic [31:0] test[], 
    int num_cycles
);
    clear_mem();
    for (int i = 0; i < $size(test); i++) begin
        i_mem[i] = test[i];
    end
    reset();
    wait (cycles == num_cycles);
endtask

function void clear_mem;
    for (int i = 0; i < MEM_SIZE - 1; i++) begin
        i_mem[i] = 32'd0;
        d_mem[i] = 32'd0;
    end
endfunction

task reset();
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
    cycles = 0;
endtask

initial begin
    run_test(test2, 100);
    $finish;
end

endmodule