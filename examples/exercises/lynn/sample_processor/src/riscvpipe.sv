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

    // IEU → IFU
    logic        PCSrcE;
    logic [31:0] PCTargetE;

    // IEU → LSU
    logic [31:0] ALUResultM, WriteDataM, PCPlus4M;
    logic [4:0]  RdM;
    logic        RegWriteM, MemWriteM, ResultSrcM, MemEnM, CSRSrcM, LinkM;
    logic [2:0]  Funct3M;
    logic [31:0] CSRReadDataM;
    logic        ValidM;

    // LSU → IEU
    logic        RegWriteW;
    logic [4:0]  RdW;
    logic [31:0] ResultW;
    logic        RetireW;

    // LSU → IEU
    logic [31:0] IEUResultM;

    // Hazard → IFU/IEU
    logic        StallF, StallD, FlushD, FlushE;

    // IEU → Hazard
    logic [4:0]  Rs1E, Rs2E, RdE;
    logic        ResultSrcE;

    // IEU → top-level: timer counter for MMIO
    logic [63:0] TimeCounter;

    logic [31:0] IEUAdrRaw;
    logic        IsTimeLo, IsTimeHi, IsTimeMMIO;
    assign IsTimeLo   = (IEUAdrRaw == 32'h0200BFF8);
    assign IsTimeHi   = (IEUAdrRaw == 32'h0200BFFC);
    assign IsTimeMMIO = IsTimeLo | IsTimeHi;

    localparam logic [31:0] DMEM_BASE = 32'h8000_0000;
    localparam logic [31:0] DMEM_MASK = 32'h007F_FFFF; // 8 MB − 1
    logic [31:0] DAdrWrapped;
    assign DAdrWrapped = DMEM_BASE | (IEUAdrRaw & DMEM_MASK);

    assign IEUAdr = IsTimeMMIO ? IEUAdrRaw : {DAdrWrapped[31:2], 2'b00};

    // ReadData mux:
    logic [31:0] ReadDataFinal;
    assign ReadDataFinal = IsTimeMMIO ?
                           (IsTimeLo ? TimeCounter[31:0] : TimeCounter[63:32]) :
                           ReadData;

    logic MemEnRaw, WriteEnRaw;
    logic [3:0] WriteByteEnRaw;
    assign MemEn       = MemEnRaw & ~IsTimeMMIO;
    assign WriteEn     = WriteEnRaw;
    assign WriteByteEn = WriteByteEnRaw;

    // ----------------------------------------------------------------
    // Pipeline stages
    // ----------------------------------------------------------------
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
        .IEUResultM,
        .RetireW,
        .PCSrcE, .PCTargetE,
        .ALUResultM, .WriteDataM, .PCPlus4M, .RdM,
        .RegWriteM, .MemWriteM, .ResultSrcM, .MemEnM, .CSRSrcM, .LinkM,
        .Funct3M, .CSRReadDataM,
        .Rs1E, .Rs2E, .RdE, .ResultSrcE,
        .ValidM,
        .TimeCounter
    );

    lsu lsu_inst (
        .clk, .reset,
        .ALUResultM, .WriteDataM, .PCPlus4M, .RdM,
        .RegWriteM, .MemWriteM, .ResultSrcM, .MemEnM, .CSRSrcM, .LinkM,
        .Funct3M, .CSRReadDataM,
        .ValidM,
        .ReadData   (ReadDataFinal),    // MMIO-muxed read data
        .IEUAdr     (IEUAdrRaw),        // raw address; wrapping done above
        .WriteData,
        .MemEn      (MemEnRaw),
        .WriteEn    (WriteEnRaw),
        .WriteByteEn(WriteByteEnRaw),
        .RegWriteW, .RdW, .ResultW,
        .RetireW,
        .IEUResultM
    );

    hazard hazard_inst (
        .RdE, .ResultSrcE,
        .Rs1D(InstrD[19:15]), .Rs2D(InstrD[24:20]),
        .PCSrcE,
        .StallF, .StallD,
        .FlushD, .FlushE
    );

endmodule
