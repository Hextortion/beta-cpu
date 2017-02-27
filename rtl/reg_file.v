///////////////////////////////////////////////////////////////////////////////
// File name: reg_file.v
// Author: Stefan Dumitrescu
// 
// Description: This file contains the register file implementation
///////////////////////////////////////////////////////////////////////////////

module reg_file(
    input clk,
    input [4:0] ra1,          // read address 1
    input [4:0] ra2,          // read address 2
    output [31:0] rd1,        // read data 1
    output [31:0] rd2,        // read data 2    
    input we,                 // write enable
    input [4:0] wa,           // write address
    input [31:0] wd           // write data
);

reg [31:0] mem [0:31];

assign rd1 = mem[ra1];
assign rd2 = mem[ra2];

always @(posedge clk) begin
    if (we && ~&wa) begin
        mem[wa] <= wd;
    end
end

endmodule