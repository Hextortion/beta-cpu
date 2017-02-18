`timescale 1ns/100ps

`include "defines.v"

module execute_tb;

logic clk;
always begin
    clk = 0;
    #10;
    clk = 1;
    #10;
end

logic [31:0] ir;
logic [31:0] a;
logic [31:0] b;
logic [31:0] y;
logic [31:0] st_mem_next;
logic [31:0] pc_mem_next;
logic [31:0] ir_mem_next;

execute dut (
    .clk(clk),
    .ir_src_exec(IR_SRC_DATA),
    .pc_exec_next(32'd0),
    .ir_exec_next(ir),
    .a_exec_next(a),
    .b_exec_next(b),
    .st_exec_next(32'd0),
    .pc_mem_next(pc_mem_next),
    .ir_mem_next(ir_mem_next),
    .y_mem_next(y),
    .st_mem_next(st_mem_next)
);

integer dut_error_counter = 0;

task test_case;
    input [5:0] test_inst;
    input [31:0] test_a;
    input [31:0] test_b;
    input [31:0] expected;
begin
    a <= test_a;
    b <= test_b;
    ir <= test_inst;
    @(posedge clk);
    if (y == expected) begin
        $display("PASS: inst=%x a=%x b=%x y=%x expected=%x",
            test_inst, test_a, test_b, y, expected);
    end else begin
        $display("** FAIL: inst=%x a=%x b=%x y=%x expected=%x",
            test_inst, test_a, test_b, y, expected);
        dut_error_counter = dut_error_counter + 1;
    end
end
endtask

initial begin
    @(posedge clk);
        test_case({`OPCODE_ADD, 5'd0, 5'd0, 16'd0}, 32'd1, 32'd2, 32'd3);
    if (dut_error_counter != 0) begin
        $display("ERROR: %d test cases failed", dut_error_counter);
    end else begin
        $display("PASS: all test cases passed");
    end
    $finish;
end

endmodule