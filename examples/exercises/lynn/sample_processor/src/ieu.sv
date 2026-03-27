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
        output  logic [63:0]    TimeCounter,
        output  logic           MemEn
    );

    logic RegWrite, Jump, Eq, LT, LTU, ALUResultSrc;
    logic [1:0] ALUSrc;
    logic [2:0] ImmSrc, ResultSrc;
    logic [2:0] ALUControl;
    logic [2:0] BranchType, LoadType;
    logic [1:0] StoreType, JumpType;
    logic [3:0] WriteByteEnRaw;
    logic [31:0] WriteDataRaw;
    logic [31:0] LoadDataExt;
    logic [31:0] DAdr;
    logic [11:0] CsrAddr;
    logic [31:0] CsrReadData;
    logic InstrRetired;
    logic Hpm3Event, Hpm4Event, Hpm5Event;
    logic Hpm6Event, Hpm7Event, Hpm8Event, Hpm9Event, Hpm10Event;

    assign CsrAddr = Instr[31:20];
    assign InstrRetired = ~reset;
    assign DAdr = 32'h8000_0000 | (IEUAdr & 32'h007F_FFFF);
    assign Hpm3Event  = ((Instr[6:0] == 7'b0110011) && (Instr[14:12] == 3'b000) && (Instr[31:25] == 7'b0000000)) || // add
                    ((Instr[6:0] == 7'b0010011) && (Instr[14:12] == 3'b000));                                      // addi

    assign Hpm4Event  = (Instr[6:0] == 7'b1100011); // any branch evaluated

    assign Hpm5Event  = (Instr[6:0] == 7'b1100011) && PCSrc; // branch taken

    assign Hpm6Event  = (Instr[6:0] == 7'b0000011); // any load
    assign Hpm7Event  = (Instr[6:0] == 7'b0100011); // any store
    assign Hpm8Event  = ((Instr[6:0] == 7'b1101111) || (Instr[6:0] == 7'b1100111)); // jal/jalr

    assign Hpm9Event  = (Instr[6:0] == 7'b0000011) &&
                        ((LoadType == 3'd0) || (LoadType == 3'd1) || (LoadType == 3'd3) || (LoadType == 3'd4));

    assign Hpm10Event = (Instr[6:0] == 7'b0100011) &&
                        ((StoreType == 2'd0) || (StoreType == 2'd1));

    csr csr(.clk(clk), .reset(reset), .InstrRetired(InstrRetired), .CsrAddr(CsrAddr), .CsrReadData(CsrReadData),
    .Hpm3Event(Hpm3Event), .Hpm4Event(Hpm4Event), .Hpm5Event(Hpm5Event), .Hpm6Event(Hpm6Event), .Hpm7Event(Hpm7Event),
    .Hpm8Event(Hpm8Event), .Hpm9Event(Hpm9Event), .Hpm10Event(Hpm10Event), .TimeCounter(TimeCounter));

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
        .PC, .PCPlus4, .Instr, .JumpType, .IEUAdr, .WriteData(WriteDataRaw), .CsrReadData(CsrReadData), .ReadData(LoadDataExt));

    lsu lsu(.Adr(IEUAdr), .StoreDataIn(WriteDataRaw), .ReadDataIn(ReadData),
        .LoadType(LoadType), .StoreType(StoreType), .StoreEn(|WriteByteEnRaw),
        .StoreDataOut(WriteData), .WriteByteEnOut(WriteByteEn), .LoadDataOut(LoadDataExt));
endmodule
