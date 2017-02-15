module reg_file(
    input logic clk,            // Clock
    input logic [5:0] ra1,      // Read address 1
    input logic [5:0] ra2,      // Read address 2
    output logic [31:0] rd1,    // Read data 1
    output logic [31:0] rd2,    // Read data 2
    input logic we,             // Write enable
    input logic [5:0] wa,       // Write address
    input logic [31:0] wd       // Write data
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
endmodule