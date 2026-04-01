// riscvpipe.sv
// Top-level 5-stage pipelined RISC-V processor
// kacassidy@hmc.edu 2025
//
// Instantiates and wires together all pipeline stages and support units:
//   ifu           — Fetch stage + IF/ID register
//   decode_stage  — Decode stage + ID/EX register
//   execute_stage — Execute stage + EX/MEM register
//   memory_stage  — Memory stage + MEM/WB register
//   writeback_stage — Writeback stage (combinational mux only)
//   csrfile       — Performance counters (cycle, instret, hpm3-10)
//   hazard        — Forwarding, load-use stall, branch/jump flush

`include "parameters.svh"

module riscvpipe (
    input  logic        clk,
    input  logic        reset,

    output logic [31:0] PC,           // instruction memory address
    input  logic [31:0] Instr,        // instruction memory read data

    output logic [31:0] IEUAdr,       // data memory address
    input  logic [31:0] ReadData,     // data memory read data
    output logic [31:0] WriteData,    // data memory write data

    output logic        MemEn,
    output logic        WriteEn,
    output logic [3:0]  WriteByteEn
);

    // ----------------------------------------------------------------
    // IF/ID wires
    // ----------------------------------------------------------------
    logic [31:0] PCPlus4F;
    logic [31:0] InstrD, PCD, PCPlus4D;

    // ----------------------------------------------------------------
    // ID/EX wires
    // ----------------------------------------------------------------
    logic [31:0] RD1E, RD2E, PCE, PCPlus4E, ImmExtE;
    logic [4:0]  Rs1E, Rs2E, RdE;
    logic        RegWriteE;
    logic [1:0]  ALUSrcE;
    logic        ALUOpE;
    logic [1:0]  ALUControlE;
    logic        ALUResultSrcE;
    logic        MemWriteE, ResultSrcE, BranchE, JumpE, MemEnE;
    logic        LUIE, CSRSrcE;
    logic [2:0]  Funct3E;
    logic        Funct7b5E;
    logic [6:0]  Funct7E;
    logic [11:0] CSRAdrE;
    logic [6:0]  OpE;

    // ----------------------------------------------------------------
    // EX/MEM wires
    // ----------------------------------------------------------------
    logic [31:0] ALUResultM_w, WriteDataM;
    logic [4:0]  RdM;
    logic        RegWriteM;
    logic        MemWriteM, ResultSrcM, MemEnM;
    logic        CSRSrcM;
    logic [2:0]  Funct3M;
    logic [31:0] PCPlus4M;
    logic [31:0] CSRReadDataM;
    logic [31:0] ResultM;

    // ----------------------------------------------------------------
    // MEM/WB wires
    // ----------------------------------------------------------------
    logic [31:0] ALUResultW, ReadDataW;
    logic [4:0]  RdW;
    logic        RegWriteW;
    logic        ResultSrcW, CSRSrcW;
    logic [31:0] PCPlus4W, CSRReadDataW;
    logic [31:0] ResultW;

    // ----------------------------------------------------------------
    // Hazard / control wires
    // ----------------------------------------------------------------
    logic        StallF, StallD, FlushD, FlushE;
    logic        PCSrcE;
    logic [31:0] PCTargetE;
    logic [1:0]  ForwardAE, ForwardBE;

    // ----------------------------------------------------------------
    // CSR read data (combinational; driven by EX-stage address)
    // BranchOp tied to 0: branch outcome not known until EX, so
    // branch-taken counts are approximate — acceptable for profiling.
    // ----------------------------------------------------------------
    logic [31:0] CSRReadDataE;

    csrfile csr (
        .clk,  .reset,
        .CSRAdr  (CSRAdrE),
        .Op      (OpE),
        .Funct3  (Funct3E),
        .Funct7b5(Funct7b5E),
        .BranchOp(1'b0),
        .CSRReadData(CSRReadDataE)
    );

    // ----------------------------------------------------------------
    // Hazard unit
    // ----------------------------------------------------------------
    hazard hu (
        .Rs1E,  .Rs2E,
        .RdM,   .RdW,
        .RegWriteM,  .RegWriteW,
        .ResultSrcM,
        .Rs1D(InstrD[19:15]),  .Rs2D(InstrD[24:20]),
        .RdE,
        .PCSrcE,
        .ForwardAE,  .ForwardBE,
        .StallF,  .StallD,
        .FlushD,  .FlushE
    );

    // ----------------------------------------------------------------
    // Pipeline stages
    // ----------------------------------------------------------------
    ifu fetch (
        .clk,  .reset,
        .StallF,  .StallD,  .FlushD,
        .PCSrcE,  .PCTargetE,
        .InstrF  (Instr),
        .PC,
        .PCPlus4F,
        .InstrD,  .PCD,  .PCPlus4D
    );

    decode_stage id_stage (
        .clk,  .reset,
        .FlushE,
        .InstrD,  .PCD,  .PCPlus4D,
        .RegWriteW,  .RdW,  .ResultW,
        .RD1E,  .RD2E,  .PCE,  .PCPlus4E,  .ImmExtE,
        .Rs1E,  .Rs2E,  .RdE,
        .RegWriteE,  .ALUSrcE,  .ALUOpE,  .ALUControlE,
        .ALUResultSrcE,  .MemWriteE,  .ResultSrcE,
        .BranchE,  .JumpE,  .MemEnE,
        .LUIE,  .CSRSrcE,
        .Funct3E,  .Funct7b5E,  .Funct7E,  .CSRAdrE,  .OpE
    );

    execute_stage ex_stage (
        .clk,  .reset,
        .ResultM,  .ResultW,
        .RD1E,  .RD2E,  .PCE,  .PCPlus4E,  .ImmExtE,
        .RdE,
        .RegWriteE,  .ALUSrcE,  .ALUControlE,
        .ALUResultSrcE,  .MemWriteE,  .ResultSrcE,
        .BranchE,  .JumpE,  .MemEnE,
        .LUIE,  .CSRSrcE,
        .Funct3E,  .Funct7b5E,  .Funct7E,  .CSRAdrE,  .OpE,
        .ForwardAE,  .ForwardBE,
        .CSRReadDataE,
        .PCSrcE,  .PCTargetE,
        .ALUResultM(ALUResultM_w),
        .WriteDataM,  .RdM,
        .RegWriteM,  .MemWriteM,  .ResultSrcM,  .MemEnM,
        .CSRSrcM,  .Funct3M,  .PCPlus4M,  .CSRReadDataM
    );

    memory_stage mem_stage (
        .clk,  .reset,
        .ALUResultM(ALUResultM_w),
        .WriteDataM,  .RdM,
        .RegWriteM,  .MemWriteM,  .ResultSrcM,  .MemEnM,
        .CSRSrcM,  .Funct3M,  .PCPlus4M,  .CSRReadDataM,
        .ReadData,
        .DataAdr    (IEUAdr),
        .WriteData,  .MemEn,  .WriteEn,  .WriteByteEn,
        .ALUResultW,  .ReadDataW,  .RdW,
        .RegWriteW,  .ResultSrcW,  .CSRSrcW,
        .PCPlus4W,  .CSRReadDataW,
        .ResultM
    );

    writeback_stage wb_stage (
        .ALUResultW,  .ReadDataW,
        .ResultSrcW,  .CSRSrcW,  .CSRReadDataW,
        .ResultW
    );

endmodule
