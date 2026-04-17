// ieu.sv
// Integer Execution Unit: performs ALU operations, calculates branch targets, and interfaces with CSR file

module ieu (
    input  logic        clk, reset,
    input  logic        FlushE,
    input  logic [31:0] InstrD, PCD, PCPlus4D,
    input  logic        RegWriteW,
    input  logic [4:0]  RdW,
    input  logic [31:0] ResultW,
    input  logic [1:0]  ForwardAE, ForwardBE,
    input  logic [31:0] IEUResultM,
    output logic        PCSrcE,
    output logic [31:0] PCTargetE,
    output logic [31:0] ALUResultM, WriteDataM,
    output logic [4:0]  RdM,
    output logic        RegWriteM, MemWriteM, ResultSrcM, MemEnM, CSRSrcM,
    output logic [2:0]  Funct3M,
    output logic [31:0] CSRReadDataM,
    output logic [4:0]  Rs1E, Rs2E, RdE,
    output logic        ResultSrcE,
    output logic [63:0] TimeCounter
);

    logic [31:0] RD1D, RD2D, ImmExtD;
    logic [2:0]  ImmSrcD;
    logic        RegWriteD, ALUResultSrcD, MemWriteD, ResultSrcD;
    logic        BranchD, JumpD, MemEnD, LuiD, CSRSrcD;
    logic [1:0]  ALUSrcD;
    logic [2:0]  ALUControlD;

    regfile rf (
        .clk,
        .we3(RegWriteW), .a3(RdW),   .wd3(ResultW),
        .a1(InstrD[19:15]),          .rd1(RD1D),
        .a2(InstrD[24:20]),          .rd2(RD2D)
    );

    extend ext (
        .instr  (InstrD[31:7]),
        .immsrc (ImmSrcD),
        .immext (ImmExtD)
    );

    controller ctrl (
        .op          (InstrD[6:0]),
        .funct3      (InstrD[14:12]),
        .funct7      (InstrD[31:25]),
        .regwrite    (RegWriteD),
        .immsrc      (ImmSrcD),
        .alusrc      (ALUSrcD),
        .alucontrol  (ALUControlD),
        .aluresultsrc(ALUResultSrcD),
        .memwrite    (MemWriteD),
        .resultsrc   (ResultSrcD),
        .branch      (BranchD),
        .jump        (JumpD),
        .memen       (MemEnD),
        .lui         (LuiD)
    );

    assign CSRSrcD = (InstrD[6:0] == 7'b1110011);

    logic [31:0] RD1E, RD2E, PCE, PCPlus4E, ImmExtE;
    logic        RegWriteE, ALUResultSrcE, MemWriteE;
    logic        BranchE, JumpE, MemEnE, LuiE, CSRSrcE_r;
    logic [1:0]  ALUSrcE;
    logic [2:0]  ALUControlE;
    logic [2:0]  Funct3E;
    logic [6:0]  Funct7E;
    logic [11:0] CSRAdrE;

    always_ff @(posedge clk or posedge reset)
        if (reset) begin
            RD1E           <= '0;  RD2E          <= '0;
            PCE            <= '0;  PCPlus4E      <= '0;  ImmExtE <= '0;
            Rs1E           <= '0;  Rs2E          <= '0;  RdE     <= '0;
            RegWriteE      <= '0;  ALUSrcE       <= '0;
            ALUControlE    <= '0;  ALUResultSrcE <= '0;
            MemWriteE      <= '0;  ResultSrcE    <= '0;
            BranchE        <= '0;  JumpE         <= '0;
            MemEnE         <= '0;  LuiE          <= '0;
            CSRSrcE_r      <= '0;
            Funct3E        <= '0;  Funct7E       <= '0;
            CSRAdrE        <= '0;
        end else if (FlushE) begin
            RD1E           <= '0;  RD2E          <= '0;
            PCE            <= '0;  PCPlus4E      <= '0;  ImmExtE <= '0;
            Rs1E           <= '0;  Rs2E          <= '0;  RdE     <= '0;
            RegWriteE      <= '0;  ALUSrcE       <= '0;
            ALUControlE    <= '0;  ALUResultSrcE <= '0;
            MemWriteE      <= '0;  ResultSrcE    <= '0;
            BranchE        <= '0;  JumpE         <= '0;
            MemEnE         <= '0;  LuiE          <= '0;
            CSRSrcE_r      <= '0;
            Funct3E        <= '0;  Funct7E       <= '0;
            CSRAdrE        <= '0;
        end else begin
            RD1E           <= RD1D;       RD2E          <= RD2D;
            PCE            <= PCD;        PCPlus4E      <= PCPlus4D;
            ImmExtE        <= ImmExtD;
            Rs1E           <= InstrD[19:15];
            Rs2E           <= InstrD[24:20];
            RdE            <= InstrD[11:7];
            RegWriteE      <= RegWriteD;
            ALUSrcE        <= ALUSrcD;
            ALUControlE    <= ALUControlD;
            ALUResultSrcE  <= ALUResultSrcD;
            MemWriteE      <= MemWriteD;
            ResultSrcE     <= ResultSrcD;
            BranchE        <= BranchD;
            JumpE          <= JumpD;
            MemEnE         <= MemEnD;
            LuiE           <= LuiD;
            CSRSrcE_r      <= CSRSrcD;
            Funct3E        <= InstrD[14:12];
            Funct7E        <= InstrD[31:25];
            CSRAdrE        <= InstrD[31:20];
        end

    logic [31:0] FSrcAE, FSrcBE;
    logic [31:0] SrcAE, SrcBE;
    logic [31:0] ALUResultE;
    logic        BranchOpE;
    logic [31:0] IEUResultE;
    logic [31:0] CSRReadDataE;

    csrfile csr (
        .clk         (clk),
        .reset       (reset),
        .csradr      (CSRAdrE),
        .csrreaddata (CSRReadDataE),
        .TimeCounter (TimeCounter)
    );

    always_comb begin
        FSrcAE = (ForwardAE == 2'b10) ? IEUResultM :
                 (ForwardAE == 2'b01) ? ResultW    : RD1E;
        FSrcBE = (ForwardBE == 2'b10) ? IEUResultM :
                 (ForwardBE == 2'b01) ? ResultW    : RD2E;
    end

    assign SrcAE = ALUSrcE[1] ? PCE     : FSrcAE;
    assign SrcBE = ALUSrcE[0] ? ImmExtE : FSrcBE;

    alu alu_inst (
        .srca      (SrcAE),
        .srcb      (SrcBE),
        .alucontrol(ALUControlE),
        .funct3    (Funct3E),
        .funct7    (Funct7E),
        .lui       (LuiE),
        .aluresult (ALUResultE)
    );

    cmp cmp_inst (
        .a       (FSrcAE),
        .b       (FSrcBE),
        .funct3  (Funct3E),
        .branchop(BranchOpE)
    );

    assign IEUResultE = ALUResultSrcE ? PCPlus4E : ALUResultE;
    assign PCTargetE  = (JumpE & ~ALUSrcE[1]) ? ALUResultE : (PCE + ImmExtE);
    assign PCSrcE     = (BranchE & BranchOpE) | JumpE;

    always_ff @(posedge clk or posedge reset)
        if (reset) begin
            ALUResultM   <= '0;  WriteDataM    <= '0;  RdM          <= '0;
            RegWriteM    <= '0;  MemWriteM     <= '0;  ResultSrcM   <= '0;
            MemEnM       <= '0;  CSRSrcM       <= '0;
            Funct3M      <= '0;  CSRReadDataM  <= '0;
        end else begin
            ALUResultM   <= IEUResultE;
            WriteDataM   <= FSrcBE;
            RdM          <= RdE;
            RegWriteM    <= RegWriteE;
            MemWriteM    <= MemWriteE;
            ResultSrcM   <= ResultSrcE;
            MemEnM       <= MemEnE;
            CSRSrcM      <= CSRSrcE_r;
            Funct3M      <= Funct3E;
            CSRReadDataM <= CSRReadDataE;
        end

endmodule
