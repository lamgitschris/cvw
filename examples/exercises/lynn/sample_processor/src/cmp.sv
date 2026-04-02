// cmp.sv
// Branch comparator — evaluates all RV32I branch conditions

module cmp (
    input  logic [31:0] a, b,
    input  logic [2:0]  funct3,
    output logic        branchop    // 1 if branch condition is satisfied
);
    logic lt, ltu;
    assign lt  = $signed(a) < $signed(b);
    assign ltu = a < b;

    always_comb
        case (funct3)
            3'b000:  branchop = (a == b);   // BEQ
            3'b001:  branchop = (a != b);   // BNE
            3'b100:  branchop = lt;          // BLT
            3'b101:  branchop = ~lt;         // BGE
            3'b110:  branchop = ltu;         // BLTU
            3'b111:  branchop = ~ltu;        // BGEU
            default: branchop = 1'b0;
        endcase
endmodule
