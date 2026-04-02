// ieu.sv
// Integer Execution Unit
//
// Spans the Decode and Execute pipeline stages (IEU blue box in block diagram).
//
// Decode:  register file reads, immediate extension, control decode, ID/EX register
// Execute: forwarding muxes, ALU, branch comparator, PC target,
//          result mux (link vs ALU), EX/MEM register

module ieu (
    input  logic        clk, reset,
    input  logic        FlushE,
    // From IFU (IF/ID register)
    input  logic [31:0] InstrD, PCD, PCPlus4D,
    // From LSU writeback
    input  logic        RegWriteW,
    input  logic [4:0]  RdW,
    input  logic [31:0] ResultW,
    // From hazard unit
    input  logic [1:0]  ForwardAE, ForwardBE,
    // MEM-stage result for forwarding (from LSU)
    input  logic [31:0] IEUResultM,
    // To IFU — branch/jump PC
    output logic        PCSrcE,
    output logic [31:0] PCTargetE,
    // EX/MEM register outputs — to LSU
    output logic [31:0] ALUResultM, WriteDataM,
    output logic [4:0]  RdM,
    output logic        RegWriteM, MemWriteM, ResultSrcM, MemEnM, CSRSrcM,
    output logic [2:0]  Funct3M,
    output logic [31:0] CSRReadDataM,
    // To hazard unit
    output logic [4:0]  Rs1E, Rs2E, RdE,
    output logic        ResultSrcE    // high when EX-stage instruction is a load
);

    // ----------------------------------------------------------------
    // DECODE STAGE
    // ----------------------------------------------------------------
    logic [31:0] RD1D, RD2D, ImmExtD;
    logic [2:0]  ImmSrcD;
    logic        RegWriteD, ALUResultSrcD, MemWriteD, ResultSrcD;
    logic        BranchD, JumpD, MemEnD, LuiD, CSRSrcD;
    logic [1:0]  ALUSrcD, ALUControlD;

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
        .funct7b5    (InstrD[30]),
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

    // CSRSrc: set for CSRRS/CSRRCI (op=1110011) so writeback selects CSR read data
    assign CSRSrcD = (InstrD[6:0] == 7'b1110011);

    // ----------------------------------------------------------------
    // ID/EX pipeline register
    // ----------------------------------------------------------------
    logic [31:0] RD1E, RD2E, PCE, PCPlus4E, ImmExtE;
    logic        RegWriteE, ALUResultSrcE, MemWriteE;
    logic        BranchE, JumpE, MemEnE, LuiE, CSRSrcE_r;
    logic [1:0]  ALUSrcE, ALUControlE;
    logic [2:0]  Funct3E;
    logic        Funct7b5E;
    logic [11:0] CSRAdrE;

    always_ff @(posedge clk or posedge reset)
        if (reset || FlushE) begin
            RD1E          <= '0;  RD2E         <= '0;
            PCE           <= '0;  PCPlus4E     <= '0;  ImmExtE <= '0;
            Rs1E          <= '0;  Rs2E         <= '0;  RdE     <= '0;
            RegWriteE     <= '0;  ALUSrcE      <= '0;
            ALUControlE   <= '0;  ALUResultSrcE <= '0;
            MemWriteE     <= '0;  ResultSrcE   <= '0;
            BranchE       <= '0;  JumpE        <= '0;
            MemEnE        <= '0;  LuiE         <= '0;
            CSRSrcE_r     <= '0;
            Funct3E       <= '0;  Funct7b5E    <= '0;
            CSRAdrE       <= '0;
        end else begin
            RD1E          <= RD1D;       RD2E     <= RD2D;
            PCE           <= PCD;        PCPlus4E <= PCPlus4D;
            ImmExtE       <= ImmExtD;
            Rs1E          <= InstrD[19:15];
            Rs2E          <= InstrD[24:20];
            RdE           <= InstrD[11:7];
            RegWriteE     <= RegWriteD;
            ALUSrcE       <= ALUSrcD;
            ALUControlE   <= ALUControlD;
            ALUResultSrcE <= ALUResultSrcD;
            MemWriteE     <= MemWriteD;
            ResultSrcE    <= ResultSrcD;
            BranchE       <= BranchD;
            JumpE         <= JumpD;
            MemEnE        <= MemEnD;
            LuiE          <= LuiD;
            CSRSrcE_r     <= CSRSrcD;
            Funct3E       <= InstrD[14:12];
            Funct7b5E     <= InstrD[30];
            CSRAdrE       <= InstrD[31:20];
        end

    // ----------------------------------------------------------------
    // EXECUTE STAGE
    // ----------------------------------------------------------------
    logic [31:0] FSrcAE, FSrcBE;   // forwarded source values
    logic [31:0] SrcAE, SrcBE;    // final ALU inputs
    logic [31:0] ALUResultE;
    logic        BranchOpE;
    logic [31:0] IEUResultE;
    logic [31:0] CSRReadDataE;

    // CSR file — reads cycle counter combinationally in EX stage
    csrfile csr (
        .clk, .reset,
        .csradr     (CSRAdrE),
        .csrreaddata(CSRReadDataE)
    );

    // Forwarding muxes: 00=regfile, 01=WB result, 10=MEM result (highest priority)
    always_comb begin
        FSrcAE = (ForwardAE == 2'b10) ? IEUResultM :
                 (ForwardAE == 2'b01) ? ResultW    : RD1E;
        FSrcBE = (ForwardBE == 2'b10) ? IEUResultM :
                 (ForwardBE == 2'b01) ? ResultW    : RD2E;
    end

    // ALU source muxes
    assign SrcAE = ALUSrcE[1] ? PCE     : FSrcAE;  // 1 = use PC  (AUIPC, JAL, branches)
    assign SrcBE = ALUSrcE[0] ? ImmExtE : FSrcBE;  // 1 = use Imm (all I/S/B/U/J types)

    alu alu_inst (
        .srca      (SrcAE),
        .srcb      (SrcBE),
        .alucontrol(ALUControlE),
        .funct3    (Funct3E),
        .funct7b5  (Funct7b5E),
        .lui       (LuiE),
        .aluresult (ALUResultE)
    );

    // Branch comparator uses pre-mux register values (not PC/Imm-muxed)
    cmp cmp_inst (
        .a      (FSrcAE),
        .b      (FSrcBE),
        .funct3 (Funct3E),
        .branchop(BranchOpE)
    );

    // Result written to Rd:
    //   ALUResultSrcE=1 (JAL/JALR): write PC+4 as link address
    //   ALUResultSrcE=0 (all else):  write ALU result
    assign IEUResultE = ALUResultSrcE ? (PCE + 32'd4) : ALUResultE;

    // Branch/jump target PC:
    //   JALR (jump, register base): target = rs1 + imm = ALUResultE
    //   JAL / branches:             target = PC  + imm (dedicated adder)
    assign PCTargetE = (JumpE & ~ALUSrcE[1]) ? ALUResultE : (PCE + ImmExtE);
    assign PCSrcE    = (BranchE & BranchOpE) | JumpE;

    // ----------------------------------------------------------------
    // EX/MEM pipeline register
    // ----------------------------------------------------------------
    always_ff @(posedge clk or posedge reset)
        if (reset) begin
            ALUResultM   <= '0;  WriteDataM   <= '0;  RdM    <= '0;
            RegWriteM    <= '0;  MemWriteM    <= '0;  ResultSrcM <= '0;
            MemEnM       <= '0;  CSRSrcM      <= '0;
            Funct3M      <= '0;  CSRReadDataM <= '0;
        end else begin
            ALUResultM   <= IEUResultE;  // link address or ALU result
            WriteDataM   <= FSrcBE;      // raw rs2 value for stores
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
