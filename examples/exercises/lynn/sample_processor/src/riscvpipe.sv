// riscvpipe.sv
// Top-level 5-stage pipelined RV32I processor
//
// Structure mirrors the block diagram:
//   IFU    — Instruction Fetch Unit (Fetch stage)
//   IEU    — Integer Execution Unit (Decode + Execute stages)
//   LSU    — Load/Store Unit        (Memory + Writeback stages)
//   Hazard — Forwarding, stall, and flush control
//
// Top-level responsibilities:
//   - DMEM address wrapping into 0x80000000–0x807FFFFC window
//   - MMIO timer: reads at 0x0200BFF8 (time lo) and 0x0200BFFC (time hi)
//     return TimeCounter from the CSR file; real RAM is not accessed

`include "parameters.svh"

module riscvpipe (
    input  logic        clk, reset,
    output logic [31:0] PC,           // to instruction memory
    input  logic [31:0] Instr,        // from instruction memory
    output logic [31:0] IEUAdr,       // data memory address (wrapped / MMIO passthrough)
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

    // IEU → top-level: timer counter for MMIO
    logic [63:0] TimeCounter;

    // ----------------------------------------------------------------
    // MMIO timer interception
    // CoreMark reads time via MMIO at 0x0200BFF8 (lo) and 0x0200BFFC (hi)
    // ----------------------------------------------------------------
    logic [31:0] IEUAdrRaw;    // raw address from LSU before wrapping
    logic        IsTimeLo, IsTimeHi, IsTimeMMIO;
    assign IsTimeLo   = (IEUAdrRaw == 32'h0200BFF8);
    assign IsTimeHi   = (IEUAdrRaw == 32'h0200BFFC);
    assign IsTimeMMIO = IsTimeLo | IsTimeHi;

    // DMEM address wrapping into 8 MB window at 0x80000000
    localparam logic [31:0] DMEM_BASE = 32'h8000_0000;
    localparam logic [31:0] DMEM_MASK = 32'h007F_FFFF; // 8 MB − 1
    logic [31:0] DAdrWrapped;
    assign DAdrWrapped = DMEM_BASE | (IEUAdrRaw & DMEM_MASK);

    // IEUAdr exposed to memory: MMIO addresses pass through raw (unmapped);
    // all other addresses are wrapped and word-aligned
    assign IEUAdr = IsTimeMMIO ? IEUAdrRaw : {DAdrWrapped[31:2], 2'b00};

    // ReadData mux: MMIO timer overrides RAM read data
    logic [31:0] ReadDataFinal;
    assign ReadDataFinal = IsTimeMMIO ?
                           (IsTimeLo ? TimeCounter[31:0] : TimeCounter[63:32]) :
                           ReadData;

    // Suppress RAM enable on MMIO reads (no actual memory access needed)
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
        .ForwardAE, .ForwardBE,
        .IEUResultM,
        .PCSrcE, .PCTargetE,
        .ALUResultM, .WriteDataM, .RdM,
        .RegWriteM, .MemWriteM, .ResultSrcM, .MemEnM, .CSRSrcM,
        .Funct3M, .CSRReadDataM,
        .Rs1E, .Rs2E, .RdE, .ResultSrcE,
        .TimeCounter
    );

    lsu lsu_inst (
        .clk, .reset,
        .ALUResultM, .WriteDataM, .RdM,
        .RegWriteM, .MemWriteM, .ResultSrcM, .MemEnM, .CSRSrcM,
        .Funct3M, .CSRReadDataM,
        .ReadData   (ReadDataFinal),    // MMIO-muxed read data
        .IEUAdr     (IEUAdrRaw),        // raw address; wrapping done above
        .WriteData,
        .MemEn      (MemEnRaw),
        .WriteEn    (WriteEnRaw),
        .WriteByteEn(WriteByteEnRaw),
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
