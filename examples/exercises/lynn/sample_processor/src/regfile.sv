// regfile.sv
// 32x32 3-port register file (x0 hardwired to 0)
// kacassidy@hmc.edu 2025

module regfile (
    input  logic        clk,
    input  logic        WE3,
    input  logic [4:0]  A1, A2, A3,
    input  logic [31:0] WD3,
    output logic [31:0] RD1, RD2
);
    logic [31:0] rf[31:1];

    // Write on rising clock edge; x0 never written
    always_ff @(posedge clk)
        if (WE3 && (A3 != 5'b0)) rf[A3] <= WD3;

    // Combinational reads; x0 always returns 0
    assign RD1 = (A1 != 0) ? rf[A1] : 32'b0;
    assign RD2 = (A2 != 0) ? rf[A2] : 32'b0;
endmodule
