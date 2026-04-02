// regfile.sv
// 32x32 3-port register file (x0 hardwired to 0)
// kacassidy@hmc.edu 2025

module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  a1, a2, a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf[31:1];

    // Write on rising clock edge; x0 never written
    always_ff @(posedge clk)
        if (we3 && (a3 != 5'b0)) rf[a3] <= wd3;

    // Combinational reads; x0 always returns 0
    assign rd1 = (a1 != 0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf[a2] : 32'b0;
endmodule
