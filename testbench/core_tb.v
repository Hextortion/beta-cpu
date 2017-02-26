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

//
// clock generation
//
initial begin
    clk <= 1'b0;
    forever begin
        #10 clk = ~clk;
    end
end

//
// reset generation
//
task reset();
    rst = 1;
    wait_cycles(6);
    rst = 0;
endtask

task wait_cycles(input [31:0] cycles);
    begin
        # (20 * cycles);
    end
endtask

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

initial begin
    for (integer i = 0; i < 32; i++) begin
        dut.decode0.rf.mem[i] = 32'd0;
    end
end

function void clear_mem;
    for (int i = 0; i < 32 - 1; i++) begin
        dut.decode0.rf.mem[i] = 32'd0;
    end
    for (int i = 0; i < MEM_SIZE - 1; i++) begin
        i_mem[i] = 32'd0;
        d_mem[i] = 32'd0;
    end
endfunction

initial begin
    process_file();
end

task process_file;
    logic [31:0] expected_rf [32];
    string str;
    int count;
    int cycles;
    int num_inst;
    int num_fail;
    int test_number;
    logic test_fail;

    int testfile = $fopen("testbench/testcases.txt", "r");
    if (!testfile) begin
        $stop;
    end

    while (!$feof(testfile)) begin
        count = $fscanf(testfile, "%s", str);
        if (str == "TEST") begin
            test_fail = 1'b0;
            count = $fscanf(testfile, "%d", test_number);
            $display("Test %d", test_number);
            count = $fscanf(testfile, "%s", str);
            if (str == "WAIT") begin
                count = $fscanf(testfile, "%d", cycles);
            end

            count = $fscanf(testfile, "%s", str);
            if (str == "RF") begin
                for (int i = 0; i < 32; i++) begin
                    count = $fscanf(testfile, "%d", expected_rf[i]);
                end
            end

            count = $fscanf(testfile, "%s", str);
            if (str == "NUM_INST") begin
                count = $fscanf(testfile, "%d", num_inst);
            end

            clear_mem();
            count = $fscanf(testfile, "%s", str);
            if (str == "INST") begin
                for (int i = 0; i < num_inst; i++) begin
                    count = $fscanf(testfile, "%x", i_mem[i]);
                end
            end
            reset();
            wait_cycles(cycles);

            for (int i = 0; i < 32; i++) begin
                if (dut.decode0.rf.mem[i] != expected_rf[i]) begin
                    $display("*** FAIL register file mismatch");
                    test_fail = 1'b1;
                    num_fail++;
                    break;
                end
            end

            if (!test_fail) begin
                $display("PASS");
            end
        end
    end

    $display("Number of test failures: %d", num_fail);

    $fclose(testfile);

    $stop;
endtask

endmodule