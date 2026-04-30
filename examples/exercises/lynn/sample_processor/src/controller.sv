// controller.sv
// Christian LamAlvarez and Anirudh Gupta
// Controller for RV32I + Zmmul multiply instructions


module controller (
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,          // full funct7 field; needed to detect Zmmul
    output logic       regwrite,
    output logic [2:0] immsrc,
    output logic [1:0] alusrc,
    output logic [2:0] alucontrol,      // 3-bit: 000=force add,001=I-type,010=Zmmul,011=R-type
    output logic       aluresultsrc,
    output logic       memwrite,
    output logic       resultsrc,
    output logic       branch,
    output logic       jump,
    output logic       memen,
    output logic       lui
);
    logic [1:0] aluop;

    // RegWrite | ImmSrc[2:0] | ALUSrc[1:0] | ALUOp[1:0] |
    // ALUResultSrc | MemWrite | ResultSrc | Branch | Jump | MemEn
    logic [13:0] controls;

    always_comb
        case (op)
            7'b0000011: controls = 14'b1_000_01_00_0_0_1_0_0_1; // load
            7'b0100011: controls = 14'b0_001_01_00_0_1_0_0_0_1; // store
            7'b0110011: controls = 14'b1_xxx_00_10_0_0_0_0_0_0; // R-type / Zmmul
            7'b0010011: controls = 14'b1_000_01_10_0_0_0_0_0_0; // I-type ALU
            7'b1100011: controls = 14'b0_010_11_00_0_0_0_1_0_0; // branch
            7'b1101111: controls = 14'b1_011_11_00_1_0_0_0_1_0; // jal
            7'b1100111: controls = 14'b1_000_01_00_1_0_0_0_1_0; // jalr
            7'b0110111: controls = 14'b1_100_01_00_0_0_0_0_0_0; // lui
            7'b0010111: controls = 14'b1_100_11_00_0_0_0_0_0_0; // auipc
            7'b1110011: controls = 14'b1_000_01_00_0_0_0_0_0_0; // csr read path
            default:    controls = 14'b0;
        endcase

    assign {regwrite, immsrc, alusrc, aluop,
            aluresultsrc, memwrite, resultsrc,
            branch, jump, memen} = controls;

    // ALU decode is kept separate from the main opcode decode so R-type, I-type,
    // and multiply instructions can share the same top-level control table.
    always_comb
        if (aluop == 2'b10) begin
            if (op[5] && funct7 == 7'b0000001)
                alucontrol = 3'b010;  // Zmmul
            else if (op[5])
                alucontrol = 3'b011;  // R-type
            else
                alucontrol = 3'b001;  // I-type
        end else
            alucontrol = 3'b000;      // force add

    // LUI bypasses the normal add/logic datapath.
    assign lui = (op == 7'b0110111);

endmodule
