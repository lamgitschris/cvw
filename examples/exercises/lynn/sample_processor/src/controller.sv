// controller.sv
// Decode-stage control: maps opcode + funct fields to all datapath control signals
// kacassidy@hmc.edu 2025
//
// ALUSrc[1]: 0=register  1=PC        (SrcA — AUIPC/JAL/branches)
// ALUSrc[0]: 0=register  1=immediate (SrcB)
// ALUOp:     0=force add path   1=use funct fields for operation select
// ALUResultSrc: 1=write PC+4 to rd (JAL/JALR link address)
// ResultSrc:    1=writeback from data memory (loads)

module controller (
    input  logic [6:0]  op,
    input  logic [2:0]  funct3,
    input  logic        funct7b5,   // instr[30]
    output logic        regwrite,
    output logic [2:0]  immsrc,
    output logic [1:0]  alusrc,
    output logic [1:0]  alucontrol,
    output logic        aluresultsrc,
    output logic        memwrite,
    output logic        resultsrc,
    output logic        branch,
    output logic        jump,
    output logic        memen,
    output logic        lui
);
    logic [11:0] controls;
    logic        aluop, sub;

    // Main decoder — one row per opcode
    // RegWrite | ImmSrc[2:0] | ALUSrc[1:0] | ALUOp | ALUResultSrc | MemWrite | ResultSrc | Branch | Jump | MemEn
    always_comb
        case (op)
            7'b0000011: controls = 12'b1_000_01_0_0_0_1_0_0_1; // loads
            7'b0100011: controls = 12'b0_001_01_0_0_1_0_0_0_1; // stores
            7'b0110011: controls = 12'b1_xxx_00_1_0_0_0_0_0_0; // R-type (incl. M-ext)
            7'b0010011: controls = 12'b1_000_01_1_0_0_0_0_0_0; // I-type ALU
            7'b1100011: controls = 12'b0_010_11_0_0_0_0_1_0_0; // branches
            7'b1101111: controls = 12'b1_011_11_0_1_0_0_0_1_0; // JAL
            7'b1100111: controls = 12'b1_000_01_0_1_0_0_0_1_0; // JALR
            7'b0110111: controls = 12'b1_100_01_0_0_0_0_0_0_0; // LUI
            7'b0010111: controls = 12'b1_100_11_0_0_0_0_0_0_0; // AUIPC
            7'b1110011: controls = 12'b1_000_01_0_0_0_0_0_0_0; // CSR reads
            default:    controls = 12'b0;
        endcase

    assign {regwrite, immsrc, alusrc, aluop,
            aluresultsrc, memwrite, resultsrc,
            branch, jump, memen} = controls;

    // ALU decoder — SUB only for R-type (op[5]=1) ADD with funct7b5 set
    assign sub        = aluop & (funct3 == 3'b000) & funct7b5 & op[5];
    assign alucontrol = {sub, aluop};

    // LUI bypasses the adder in the ALU — pass as dedicated signal
    assign lui = (op == 7'b0110111);
endmodule
