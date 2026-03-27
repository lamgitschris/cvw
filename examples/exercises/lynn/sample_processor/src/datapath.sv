// riscvsingle.sv
// RISC-V single-cycle processor
// David_Harris@hmc.edu 2020

module datapath(
        input   logic           clk, reset,
        input   logic [2:0]     Funct3,
        input   logic           ALUResultSrc,
        input   logic [2:0]     ResultSrc,
        input   logic [1:0]     ALUSrc,
        input   logic           RegWrite,
        input   logic [2:0]     ImmSrc,
        input   logic [2:0]     ALUControl,
        input   logic [31:0]    CsrReadData,
        output  logic           Eq,
        output  logic           LT,
        output  logic           LTU,
        input   logic [31:0]    PC, PCPlus4,
        input   logic [31:0]    Instr,
        input   logic [1:0]    JumpType,
        output  logic [31:0]    IEUAdr, WriteData,
        input   logic [31:0]    ReadData
    );

    logic [31:0] ImmExt;
    logic [31:0] R1, R2, SrcA, SrcB;
    logic [31:0] ALUResult, IEUResult, ResultPre, ResultMid, Result;

    // Added
    logic [31:0] IEUAdrRaw;

    // register file logic
    regfile rf(.clk, .WE3(RegWrite), .A1(Instr[19:15]), .A2(Instr[24:20]),
        .A3(Instr[11:7]), .WD3(Result), .RD1(R1), .RD2(R2));

    extend ext(.Instr(Instr[31:7]), .ImmSrc, .ImmExt);

    // ALU logic
    cmp cmp(.R1, .R2, .Eq, .LT, .LTU);

    mux2 #(32) srcamux(R1, PC, ALUSrc[1], SrcA);
    mux2 #(32) srcbmux(R2, ImmExt, ALUSrc[0], SrcB);

    alu alu(.SrcA, .SrcB, .ALUControl, .Funct3, .Funct7(Instr[31:25]), .ALUResult, .IEUAdr(IEUAdrRaw));

    mux2 #(32) ieuresultmux(ALUResult, PCPlus4, ALUResultSrc, IEUResult);
    // Two stage select for immext addition; three stage to make sure we can do CSR
    mux2 #(32) resultmux0(IEUResult, ReadData, ResultSrc[0], ResultPre);
    mux2 #(32) resultmux1(ResultPre, ImmExt,   ResultSrc[1], ResultMid);
    mux2 #(32) resultmux2(ResultMid, CsrReadData, ResultSrc[2], Result);

    // Jump Logic
    // JumpType encodings from controller: J_NONE=0, J_JAL=1, J_JALR=2
    assign IEUAdr = (JumpType == 2'd2) ? {IEUAdrRaw[31:1], 1'b0} : IEUAdrRaw;

    assign WriteData = R2;
endmodule
