///////////////////////////////////////////////////////////////////////////////
//  File name: reg_file.v
//  Author: Stefan Dumitrescu
//  
//  Description: This file contains the register file implementation
///////////////////////////////////////////////////////////////////////////////

module reg_file(
    input logic clk,            // clock
    input logic [5:0] ra1,      // read address 1
    input logic [5:0] ra2,      // read address 2
    output logic [31:0] rd1,    // read data 1
    output logic [31:0] rd2,    // read data 2
    input logic we,             // write enable
    input logic [5:0] wa,       // write address
    input logic [31:0] wd       // write data
);

logic [31:0] mem[0:31];

always_comb begin
    rd1 = mem[ra1];
    rd2 = mem[ra2];
end

always_ff @(posedge clk) begin
    if (we) begin
        mem[wa] <= wd;
    end
end
endmodule