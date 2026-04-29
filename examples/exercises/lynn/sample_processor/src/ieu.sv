// ieu.sv
// Integer Execution Unit: performs ALU operations, calculates branch targets,
// interfaces with CSR file, performs inline branch compare, and tracks valid instructions into MEM.

module ieu (
    input  logic        clk, reset,
    input  logic        FlushE,
    input  logic [31:0] InstrD, PCD, PCPlus4D,
    input  logic        RegWriteW,
    input  logic [4:0]  RdW,
    input  logic [31:0] ResultW,
    input  logic [31:0] IEUResultM,
    input  logic        RetireW,
    output logic        PCSrcE,
    output logic [31:0] PCTargetE,
    output logic [31:0] ALUResultM, WriteDataM, PCPlus4M,
    output logic [4:0]  RdM,
    output logic        RegWriteM, MemWriteM, ResultSrcM, MemEnM, CSRSrcM, LinkM,
    output logic [2:0]  Funct3M,
    output logic [31:0] CSRReadDataM,
    output logic [4:0]  Rs1E, Rs2E, RdE,
    output logic        ResultSrcE,
    output logic        ValidM,
    output logic [63:0] TimeCounter
);

    logic [31:0] RD1D, RD2D, ImmExtD;
    logic [2:0]  ImmSrcD;
    logic        RegWriteD, ALUResultSrcD, MemWriteD, ResultSrcD;
    logic        BranchD, JumpD, MemEnD, LuiD, CSRSrcD;
    logic [1:0]  ALUSrcD;
    logic [2:0]  ALUControlD;
    logic        ValidD;

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
    assign ValidD  = (InstrD != 32'b0);

    logic [31:0] RD1E, RD2E, PCE, PCPlus4E, ImmExtE;
    logic        RegWriteE, ALUResultSrcE, MemWriteE;
    logic        BranchE, JumpE, MemEnE, LuiE, CSRSrcE_r;
    logic [1:0]  ALUSrcE;
    logic [2:0]  ALUControlE;
    logic [2:0]  Funct3E;
    logic [6:0]  Funct7E;
    logic [11:0] CSRAdrE;
    logic        ValidE;

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
            ValidE         <= '0;
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
            ValidE         <= '0;
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
            ValidE         <= ValidD;
        end

    logic [31:0] FSrcAE, FSrcBE;
    logic [31:0] SrcAE, SrcBE;
    logic        MatchMA, MatchWA, MatchMB, MatchWB;
    logic [31:0] ALUResultE;
    logic [31:0] JalrTargetE_raw, JalrTargetE;
    logic        BranchOpE;
    logic        LtE, LtuE;
    logic [31:0] CSRReadDataE;

    csrfile csr (
        .clk         (clk),
        .reset       (reset),
        .csradr      (CSRAdrE),
        .ValidM      (ValidM),
        .RetireW     (RetireW),
        .csrreaddata (CSRReadDataE),
        .TimeCounter (TimeCounter)
    );

    // Direct forwarding logic inside IEU to avoid an encode/decode control path
    // from hazard into the operand muxes. MEM has priority over WB.
    assign MatchMA = RegWriteM && (RdM != 5'd0) && (RdM == Rs1E);
    assign MatchWA = RegWriteW && (RdW != 5'd0) && (RdW == Rs1E) && !MatchMA;
    assign MatchMB = RegWriteM && (RdM != 5'd0) && (RdM == Rs2E);
    assign MatchWB = RegWriteW && (RdW != 5'd0) && (RdW == Rs2E) && !MatchMB;

    always_comb begin
        FSrcAE = MatchMA ? IEUResultM :
                 MatchWA ? ResultW    : RD1E;
        FSrcBE = MatchMB ? IEUResultM :
                 MatchWB ? ResultW    : RD2E;
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

    assign LtE  = $signed(FSrcAE) < $signed(FSrcBE);
    assign LtuE = FSrcAE < FSrcBE;

    always_comb begin
        case (Funct3E)
            3'b000:  BranchOpE = (FSrcAE == FSrcBE); // BEQ
            3'b001:  BranchOpE = (FSrcAE != FSrcBE); // BNE
            3'b100:  BranchOpE = LtE;                // BLT
            3'b101:  BranchOpE = ~LtE;               // BGE
            3'b110:  BranchOpE = LtuE;               // BLTU
            3'b111:  BranchOpE = ~LtuE;              // BGEU
            default:  BranchOpE = 1'b0;
        endcase
    end

    // Compute the JALR target with a dedicated adder so next-PC generation
    // does not have to wait on the full ALU datapath. Also keep the link-result
    // mux out of EX by carrying PC+4 and the link-select bit into MEM/WB.
    assign JalrTargetE_raw = FSrcAE + ImmExtE;
    assign JalrTargetE     = {JalrTargetE_raw[31:1], 1'b0};
    assign PCTargetE       = (JumpE & ~ALUSrcE[1]) ? JalrTargetE : (PCE + ImmExtE);
    assign PCSrcE          = (BranchE & BranchOpE) | JumpE;

    always_ff @(posedge clk or posedge reset)
        if (reset) begin
            ALUResultM   <= '0;  WriteDataM    <= '0;  PCPlus4M     <= '0;  RdM          <= '0;
            RegWriteM    <= '0;  MemWriteM     <= '0;  ResultSrcM   <= '0;
            MemEnM       <= '0;  CSRSrcM       <= '0;  LinkM        <= '0;
            Funct3M      <= '0;  CSRReadDataM  <= '0;
            ValidM       <= '0;
        end else begin
            ALUResultM   <= ALUResultE;
            WriteDataM   <= FSrcBE;
            PCPlus4M     <= PCPlus4E;
            RdM          <= RdE;
            RegWriteM    <= RegWriteE;
            MemWriteM    <= MemWriteE;
            ResultSrcM   <= ResultSrcE;
            MemEnM       <= MemEnE;
            CSRSrcM      <= CSRSrcE_r;
            LinkM        <= ALUResultSrcE;
            Funct3M      <= Funct3E;
            CSRReadDataM <= CSRReadDataE;
            ValidM       <= ValidE;
        end

endmodule
