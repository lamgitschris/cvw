// controller.sv
// Decode-stage control: maps opcode + funct fields to all datapath control signals
//
// ALUSrc[1] — SrcA mux:   0=register file   1=PC         (AUIPC, JAL, branches)
// ALUSrc[0] — SrcB mux:   0=register file   1=immediate  (I/S/B/U/J types)
// ALUOp     — ALU decoder: 0=force add path  1=use funct fields
// ALUResultSrc — result mux: 1=write PC+4 to Rd (JAL/JALR link address)
// ResultSrc    — WB mux:     1=write load data to Rd
// MemEn     — enable data memory read or write

module controller (
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5,        // instr[30]
    output logic       regwrite,
    output logic [2:0] immsrc,
    output logic [1:0] alusrc,
    output logic [1:0] alucontrol,
    output logic       aluresultsrc,
    output logic       memwrite,
    output logic       resultsrc,
    output logic       branch,
    output logic       jump,
    output logic       memen,
    output logic       lui
);
    logic [1:0] aluop;
    logic       sub;

    // Main decoder — one hot row per opcode
    // Fields: RegWrite | ImmSrc[2:0] | ALUSrc[1:0] | ALUOp[1:0] | ALUResultSrc | MemWrite | ResultSrc | Branch | Jump | MemEn
    logic [13:0] controls;
    always_comb
        case (op)
            // loads   — I-type; reads memory; writes load data to Rd
            7'b0000011: controls = 14'b1_000_01_00_0_0_1_0_0_1;
            // stores  — S-type; writes memory; no Rd write
            7'b0100011: controls = 14'b0_001_01_00_0_1_0_0_0_1;
            // R-type  — uses funct fields for ALU operation
            7'b0110011: controls = 14'b1_xxx_00_10_0_0_0_0_0_0;
            // I-type ALU — immediate; uses funct fields
            7'b0010011: controls = 14'b1_000_01_10_0_0_0_0_0_0;
            // branches — B-type; no Rd write; comparison in cmp unit
            7'b1100011: controls = 14'b0_010_11_00_0_0_0_1_0_0;
            // JAL     — J-type; writes PC+4 link to Rd; jumps
            7'b1101111: controls = 14'b1_011_11_00_1_0_0_0_1_0;
            // JALR    — I-type; writes PC+4 link to Rd; jumps via rs1+imm
            7'b1100111: controls = 14'b1_000_01_00_1_0_0_0_1_0;
            // LUI     — U-type; passes immediate directly (lui flag bypasses adder)
            7'b0110111: controls = 14'b1_100_01_00_0_0_0_0_0_0;
            // AUIPC   — U-type; SrcA=PC, SrcB=Imm, ALU adds them
            7'b0010111: controls = 14'b1_100_11_00_0_0_0_0_0_0;
            // CSR     — reads cycle/instret counter; RegWrite passes CSR data to Rd
            7'b1110011: controls = 14'b1_000_01_00_0_0_0_0_0_0;
            default:    controls = 14'b0;
        endcase

    assign {regwrite, immsrc, alusrc, aluop,
            aluresultsrc, memwrite, resultsrc,
            branch, jump, memen} = controls;

    // ALU decoder: SUB only for R-type ADD when funct7b5 is set
    assign sub        = aluop[1] & (funct3 == 3'b000) & funct7b5 & op[5];
    assign alucontrol = {sub, aluop[1]};

    // LUI bypasses the adder — just passes the immediate through the ALU
    assign lui = (op == 7'b0110111);

endmodule
