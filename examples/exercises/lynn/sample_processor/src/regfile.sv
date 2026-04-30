// regfile.sv
// Christian LamAlvarez and Anirudh Gupta
// 32x32 register file — two async read ports, one sync write port


module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  a1, a2, a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf[31:1];

    // x0 is not physically stored; writes to it are ignored.
    always_ff @(posedge clk)
        if (we3 && a3 != '0) rf[a3] <= wd3;

    // Same-cycle WB-to-ID bypass avoids needing an extra stall when decode reads a
    // register that is being written back in the current cycle.
    assign rd1 = (a1 != '0) ? ((we3 && a3 == a1) ? wd3 : rf[a1]) : 32'b0;
    assign rd2 = (a2 != '0) ? ((we3 && a3 == a2) ? wd3 : rf[a2]) : 32'b0;
endmodule
