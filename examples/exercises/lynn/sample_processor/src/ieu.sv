// riscvsingle.sv
// RISC-V single-cycle processor
// David_Harris@hmc.edu 2020

`include "parameters.svh"

module ieu(
        input   logic           clk, reset,
        input   logic [31:0]    Instr,
        input   logic [31:0]    PC, PCPlus4,
        output  logic           PCSrc,
        output  logic [3:0]     WriteByteEn,
        output  logic [31:0]    IEUAdr, WriteData,
        input   logic [31:0]    ReadData,
        output  logic           MemEn
    );

    logic RegWrite, Jump, Eq, LT, LTU, ALUResultSrc;
    logic [1:0] ALUSrc, ResultSrc;
    logic [2:0] ImmSrc;
    logic [1:0] ALUControl;
    logic [2:0] BranchType, LoadType;
    logic [1:0] StoreType, JumpType;
    logic [3:0] WriteByteEnRaw;
    logic [31:0] WriteDataRaw;
    logic [31:0] LoadDataExt;
    logic [31:0] DAdr;

    assign DAdr = 32'h8000_0000 | (IEUAdr & 32'h007F_FFFF);

    controller c(.Op(Instr[6:0]), .Eq, .LT, .LTU, .Funct3(Instr[14:12]), .Funct7(Instr[31:25]),
        .ALUResultSrc, .ResultSrc, .WriteByteEn(WriteByteEnRaw), .PCSrc,
        .ALUSrc, .RegWrite, .ImmSrc, .ALUControl, .MemEn,
        .BranchType, .LoadType, .StoreType, .JumpType
    `ifdef DEBUG
        , .insn_debug(Instr)
    `endif
    );

    datapath dp(.clk, .reset, .Funct3(Instr[14:12]),
        .ALUResultSrc, .ResultSrc, .ALUSrc, .RegWrite, .ImmSrc, .ALUControl, .Eq, .LT, .LTU,
        .PC, .PCPlus4, .Instr, .JumpType, .IEUAdr, .WriteData(WriteDataRaw), .ReadData(LoadDataExt));

    lsu lsu(.Adr(IEUAdr), .StoreDataIn(WriteDataRaw), .ReadDataIn(ReadData),
        .LoadType(LoadType), .StoreType(StoreType), .StoreEn(|WriteByteEnRaw),
        .StoreDataOut(WriteData), .WriteByteEnOut(WriteByteEn), .LoadDataOut(LoadDataExt));
endmodule
