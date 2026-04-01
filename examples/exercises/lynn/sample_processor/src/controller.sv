// controller.sv
// Main decoder and ALU decoder — decode stage control logic
// kacassidy@hmc.edu 2025

// ------------------------------------------------------------
// Main decoder: maps opcode to all datapath control signals
// ------------------------------------------------------------
module maindec (
    input  logic [6:0]  Op,
    output logic        RegWrite,
    output logic [2:0]  ImmSrc,
    output logic [1:0]  ALUSrc,
    output logic        ALUOp,
    output logic        ALUResultSrc,  // 1 = use PC+4 as result (JAL/JALR link)
    output logic        MemWrite,
    output logic        ResultSrc,     // 1 = writeback from memory (loads)
    output logic        Branch,
    output logic        Jump,
    output logic        MemEn,
    output logic        LUI
);
    logic [12:0] controls;

    // Encoding: RegWrite_ImmSrc[2:0]_ALUSrc[1:0]_ALUOp_ALUResultSrc_MemWrite_ResultSrc_Branch_Jump_MemEn
    always_comb
        case (Op)
            7'b0000011: controls = 13'b1_000_01_0_0_0_1_0_0_1; // loads  (lb/lh/lw/lbu/lhu)
            7'b0100011: controls = 13'b0_001_01_0_0_1_0_0_0_1; // stores (sb/sh/sw)
            7'b0110011: controls = 13'b1_xxx_00_1_0_0_0_0_0_0; // R-type
            7'b0010011: controls = 13'b1_000_01_1_0_0_0_0_0_0; // I-type ALU
            7'b1100011: controls = 13'b0_010_11_0_0_0_0_1_0_0; // branches
            7'b1101111: controls = 13'b1_011_11_0_1_0_0_0_1_0; // jal
            7'b1100111: controls = 13'b1_000_01_0_1_0_0_0_1_0; // jalr
            7'b0110111: controls = 13'b1_100_01_0_0_0_0_0_0_0; // lui
            7'b0010111: controls = 13'b1_100_11_0_0_0_0_0_0_0; // auipc
            7'b1110011: controls = 13'b1_000_01_0_0_0_0_0_0_0; // csr (csrrs/csrrci)
            default:    controls = 13'b0;
        endcase

    assign {RegWrite, ImmSrc, ALUSrc, ALUOp,
            ALUResultSrc, MemWrite, ResultSrc,
            Branch, Jump, MemEn} = controls;

    assign LUI = (Op == 7'b0110111);
endmodule

// ------------------------------------------------------------
// ALU decoder: selects ALUControl from funct fields
// ------------------------------------------------------------
module aludec (
    input  logic        ALUOp,
    input  logic [2:0]  Funct3,
    input  logic        Funct7b5,
    input  logic        OpBit5,    // Op[5]: distinguishes R-type SUB from I-type ADDI
    output logic [1:0]  ALUControl
);
    logic Sub;
    assign Sub        = ALUOp & (Funct3 == 3'b000) & Funct7b5 & OpBit5;
    assign ALUControl = {Sub, ALUOp};
endmodule
