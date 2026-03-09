// riscvsingle.sv
// RISC-V single-cycle processor
// David_Harris@hmc.edu 2020 kacassidy@hmc.edu 2025

`include "parameters.svh"

module riscvsingle (
        input   logic           clk,
        input   logic           reset,

        output  logic [31:0]    PC,  // instruction memory target address
        input   logic [31:0]    Instr, // instruction memory read data

        output  logic [31:0]    IEUAdr,  // data memory target address
        input   logic [31:0]    ReadData, // data memory read data
        output  logic [31:0]    WriteData, // data memory write data

        output  logic           MemEn,
        output  logic           WriteEn,
        output  logic [3:0]     WriteByteEn  // strobes, 1 hot stating weather a byte should be written on a store
    );

    logic [31:0] PCPlus4;
    logic PCSrc;
    logic Load;

    // Memory Bounding
    logic [31:0] IEUAdrRaw;
    logic [31:0] DAdr;
    logic [31:0] DAdrWrapped;

    // Time Counting Csr
    logic [63:0] TimeCounter;
    logic [31:0] ReadDataMem, ReadDataFinal, ReadDataMMIO;
    logic IsTimeLo, IsTimeHi, IsTimeMMIO;
    logic MemEnRAM;
    logic [3:0] WriteByteEnRAM;
    logic        MemEnIEU;
    logic [3:0]  WriteByteEnIEU;
    logic [31:0] WriteDataIEU;

    // Address Checks
    assign IsTimeLo   = (IEUAdrRaw == 32'h0200BFF8);
    assign IsTimeHi   = (IEUAdrRaw == 32'h0200BFFC);
    assign IsTimeMMIO = IsTimeLo | IsTimeHi;

    // MMIO read mux
    assign ReadDataMem = ReadData;
    assign ReadDataMMIO = IsTimeLo ? TimeCounter[31:0] :
                      IsTimeHi ? TimeCounter[63:32] :
                                 32'b0;

    assign ReadDataFinal = IsTimeMMIO ? ReadDataMMIO : ReadDataMem;

    // No RAM access when timer address
    assign MemEnRAM       = MemEnIEU & ~IsTimeMMIO;
    assign WriteByteEnRAM = IsTimeMMIO ? 4'b0000 : WriteByteEnIEU;

    // Memory Bound Error Update
    localparam logic [31:0] DMEM_BASE = 32'h8000_0000;
    localparam logic [31:0] DMEM_MASK = 32'h007F_FFFF; // 8MB-1 (matches TOP=0x807ffffc)

    ifu ifu(.clk, .reset, .PCSrc, .IEUAdr(IEUAdrRaw), .PC, .PCPlus4);
    ieu ieu(.clk, .reset, .Instr, .PC, .PCPlus4, .PCSrc, .WriteByteEn(WriteByteEnIEU),
        .IEUAdr(IEUAdrRaw), .WriteData(WriteDataIEU), .ReadData(ReadDataFinal), .MemEn(MemEnIEU), .TimeCounter(TimeCounter)
    );

    assign DAdrWrapped = DMEM_BASE | (IEUAdrRaw & DMEM_MASK);
    assign DAdr = {DAdrWrapped[31:2], 2'b00};
    assign IEUAdr = IsTimeMMIO ? IEUAdrRaw : DAdr;

    assign WriteData   = WriteDataIEU;
    assign WriteEn     = |WriteByteEnRAM;
    assign WriteByteEn = WriteByteEnRAM;
    assign MemEn       = MemEnRAM;
endmodule
