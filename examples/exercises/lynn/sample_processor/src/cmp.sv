// cmp.sv
// Branch comparator — evaluates all RV32I branch conditions combinationally
// kacassidy@hmc.edu 2025

module cmp (
    input  logic [31:0] R1, R2,
    input  logic [2:0]  Funct3,
    output logic        BranchOp
);
    logic lt, ltu;
    assign lt  = ($signed(R1) < $signed(R2));
    assign ltu = (R1 < R2);

    always_comb
        case (Funct3)
            3'b000:  BranchOp = (R1 == R2);  // BEQ
            3'b001:  BranchOp = (R1 != R2);  // BNE
            3'b100:  BranchOp = lt;           // BLT
            3'b101:  BranchOp = ~lt;          // BGE
            3'b110:  BranchOp = ltu;          // BLTU
            3'b111:  BranchOp = ~ltu;         // BGEU
            default: BranchOp = 1'b0;
        endcase
endmodule
