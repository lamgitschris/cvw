// riscvpipe.sv
// Top-level 5-stage pipelined RV32I processor
//
// Structure mirrors the block diagram:
//   IFU    — Instruction Fetch Unit (Fetch stage)
//   IEU    — Integer Execution Unit (Decode + Execute stages)
//   LSU    — Load/Store Unit        (Memory + Writeback stages)
//   Hazard — Forwarding, stall, and flush control

`include "parameters.svh"

module riscvpipe (
    input  logic        clk, reset,
    output logic [31:0] PC,           // to instruction memory
    input  logic [31:0] Instr,        // from instruction memory
    output logic [31:0] IEUAdr,       // data memory address
    input  logic [31:0] ReadData,     // data memory read data
    output logic [31:0] WriteData,    // data memory write data
    output logic        MemEn,        // data memory enable
    output logic        WriteEn,      // data memory write enable
    output logic [3:0]  WriteByteEn   // data memory byte enables
);

    // IFU → IEU
    logic [31:0] InstrD, PCD, PCPlus4D;

    // IEU → IFU  (branch/jump redirect)
    logic        PCSrcE;
    logic [31:0] PCTargetE;

    // IEU → LSU  (EX/MEM pipeline register contents)
    logic [31:0] ALUResultM, WriteDataM;
    logic [4:0]  RdM;
    logic        RegWriteM, MemWriteM, ResultSrcM, MemEnM, CSRSrcM;
    logic [2:0]  Funct3M;
    logic [31:0] CSRReadDataM;

    // LSU → IEU  (writeback)
    logic        RegWriteW;
    logic [4:0]  RdW;
    logic [31:0] ResultW;

    // LSU → IEU  (MEM-stage forwarding)
    logic [31:0] IEUResultM;

    // Hazard → IFU/IEU
    logic        StallF, StallD, FlushD, FlushE;
    logic [1:0]  ForwardAE, ForwardBE;

    // IEU → Hazard
    logic [4:0]  Rs1E, Rs2E, RdE;
    logic        ResultSrcE;

    ifu ifu_inst (
        .clk, .reset,
        .StallF, .StallD, .FlushD,
        .PCSrcE, .PCTargetE,
        .Instr,
        .PC,
        .InstrD, .PCD, .PCPlus4D
    );

    ieu ieu_inst (
        .clk, .reset,
        .FlushE,
        .InstrD, .PCD, .PCPlus4D,
        .RegWriteW, .RdW, .ResultW,
        .ForwardAE, .ForwardBE,
        .IEUResultM,
        .PCSrcE, .PCTargetE,
        .ALUResultM, .WriteDataM, .RdM,
        .RegWriteM, .MemWriteM, .ResultSrcM, .MemEnM, .CSRSrcM,
        .Funct3M, .CSRReadDataM,
        .Rs1E, .Rs2E, .RdE, .ResultSrcE
    );

    lsu lsu_inst (
        .clk, .reset,
        .ALUResultM, .WriteDataM, .RdM,
        .RegWriteM, .MemWriteM, .ResultSrcM, .MemEnM, .CSRSrcM,
        .Funct3M, .CSRReadDataM,
        .ReadData,
        .IEUAdr, .WriteData, .MemEn, .WriteEn, .WriteByteEn,
        .RegWriteW, .RdW, .ResultW,
        .IEUResultM
    );

    hazard hazard_inst (
        .Rs1E, .Rs2E, .RdE, .ResultSrcE,
        .RdM, .RdW,
        .RegWriteM, .RegWriteW,
        .Rs1D(InstrD[19:15]), .Rs2D(InstrD[24:20]),
        .PCSrcE,
        .ForwardAE, .ForwardBE,
        .StallF, .StallD,
        .FlushD, .FlushE
    );

endmodule
