// regfile.sv
// 32x32 register file — two async read ports, one sync write port
//
// x0 is hardwired to zero and can never be written.

module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  a1, a2, a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf[31:1];

    always_ff @(posedge clk)
        if (we3 && a3 != '0) rf[a3] <= wd3;

    // Write-before-read: if a read port addresses the register currently being
    // written, bypass the flip-flop and return the new write data combinationally.
    // This closes the 2-instruction-gap hazard where WB and ID overlap in the
    // same cycle and the forwarding unit can no longer see the write in WB.
    assign rd1 = (a1 != '0) ? ((we3 && a3 == a1) ? wd3 : rf[a1]) : 32'b0;
    assign rd2 = (a2 != '0) ? ((we3 && a3 == a2) ? wd3 : rf[a2]) : 32'b0;
endmodule
