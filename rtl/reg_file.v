///////////////////////////////////////////////////////////////////////////////
//  File name: reg_file.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the register file implementation
///////////////////////////////////////////////////////////////////////////////

module reg_file(
    input logic clk,
    input logic [4:0] ra1,          // read address 1
    input logic [4:0] ra2,          // read address 2
    output logic [31:0] rd1,        // read data 1
    output logic [31:0] rd2,        // read data 2    
    input logic we,                 // write enable
    input logic [4:0] wa,           // write address
    input logic [31:0] wd           // write data
);

logic [31:0] mem [0:31];

// This is a hack so that the simulation will work correctly.
// TODO: Figure out how to set all the registers to zero on a reset
initial begin
    for (integer i = 0; i < 32; i++) begin
        mem[i] = 32'd0;
    end
end

always_comb begin
    rd1 = mem[ra1];
    rd2 = mem[ra2];
end

always_ff @(posedge clk) begin
    if (we && wa != 5'd31) begin
        mem[wa] <= wd;
    end
end

endmodule