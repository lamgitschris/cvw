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

    // Memory Bound Error Update
    logic [31:0] IEUAdrRaw;
    logic [31:0] DAdr;

    localparam logic [31:0] DMEM_BASE = 32'h8000_0000;
    localparam logic [31:0] DMEM_MASK = 32'h007F_FFFF; // 8MB-1 (matches TOP=0x807ffffc)

    ifu ifu(.clk, .reset, .PCSrc, .IEUAdr(IEUAdrRaw), .PC, .PCPlus4);
    ieu ieu(.clk, .reset, .Instr, .PC, .PCPlus4, .PCSrc, .WriteByteEn,
            .IEUAdr(IEUAdrRaw), .WriteData, .ReadData, .MemEn
        );

    logic [31:0] DAdrWrapped;

    assign DAdrWrapped = DMEM_BASE | (IEUAdrRaw & DMEM_MASK);
    assign DAdr = {DAdrWrapped[31:2], 2'b00};  // word-align for RAM
    assign IEUAdr = DAdr;

    assign WriteEn = |WriteByteEn;
endmodule
