// execute_stage.sv
// Execute stage — ALU, forwarding muxes, branch resolution, EX/MEM pipeline register
// kacassidy@hmc.edu 2025
//
// Branch/jump resolution happens here (EX stage).
// PCSrcE goes high when a branch is taken or any jump is encountered.
// PCTargetE selects PC+imm for branches/JAL, or the ALU result (rs1+imm) for JALR.

module execute_stage (
    input  logic        clk, reset,
    // Forwarded values from MEM and WB stages
    input  logic [31:0] ResultM, ResultW,
    // From ID/EX pipeline register — data
    input  logic [31:0] RD1E, RD2E, PCE, PCPlus4E, ImmExtE,
    input  logic [4:0]  RdE,
    // From ID/EX pipeline register — control
    input  logic        RegWriteE,
    input  logic [1:0]  ALUSrcE,
    input  logic [1:0]  ALUControlE,
    input  logic        ALUResultSrcE,
    input  logic        MemWriteE, ResultSrcE,
    input  logic        BranchE, JumpE, MemEnE,
    input  logic        LUIE, CSRSrcE,
    input  logic [2:0]  Funct3E,
    input  logic        Funct7b5E,
    input  logic [6:0]  Funct7E,
    input  logic [11:0] CSRAdrE,
    input  logic [6:0]  OpE,
    // Forwarding selects from hazard unit
    input  logic [1:0]  ForwardAE, ForwardBE,
    // CSR read data (combinational from csrfile)
    input  logic [31:0] CSRReadDataE,

    // To hazard unit and IFU
    output logic        PCSrcE,
    output logic [31:0] PCTargetE,

    // EX/MEM pipeline register outputs
    output logic [31:0] ALUResultM,
    output logic [31:0] WriteDataM,
    output logic [4:0]  RdM,
    output logic        RegWriteM,
    output logic        MemWriteM, ResultSrcM, MemEnM,
    output logic        CSRSrcM,
    output logic [2:0]  Funct3M,
    output logic [31:0] PCPlus4M,
    output logic [31:0] CSRReadDataM
);
    // ---- Forwarding muxes ----
    // SrcAE_pre / SrcBE_pre: forwarded register values before the ALU source mux
    logic [31:0] SrcAE_pre, SrcBE_pre;
    mux3 #(32) fwdAmux(RD1E, ResultW, ResultM, ForwardAE, SrcAE_pre);
    mux3 #(32) fwdBmux(RD2E, ResultW, ResultM, ForwardBE, SrcBE_pre);

    // ---- ALU source muxes ----
    // SrcA: register value  OR  PC (for auipc/jal)
    // SrcB: register value  OR  immediate
    logic [31:0] SrcAE, SrcBE;
    mux2 #(32) srcamux(SrcAE_pre, PCE,    ALUSrcE[1], SrcAE);
    mux2 #(32) srcbmux(SrcBE_pre, ImmExtE, ALUSrcE[0], SrcBE);

    // ---- ALU ----
    logic [31:0] ALUResultE, IEUAdrE;
    alu alu_inst(
        .SrcA(SrcAE), .SrcB(SrcBE),
        .ALUControl(ALUControlE),
        .Funct3(Funct3E), .Funct7b5(Funct7b5E), .Funct7(Funct7E),
        .LUI(LUIE),
        .ALUResult(ALUResultE), .IEUAdr(IEUAdrE)
    );

    // ---- Branch comparator ----
    // Uses pre-mux register values (not the PC-muxed SrcA)
    logic BranchOpE;
    cmp cmp_inst(.R1(SrcAE_pre), .R2(SrcBE_pre), .Funct3(Funct3E), .BranchOp(BranchOpE));

    // ---- Link / result mux ----
    // JAL/JALR write PC+4 as the link value; all other instructions write the ALU result
    logic [31:0] IEUResultE;
    mux2 #(32) linkresultmux(ALUResultE, PCPlus4E, ALUResultSrcE, IEUResultE);

    // ---- Branch/jump target ----
    // Branches and JAL: PC + sign-extended immediate
    // JALR:             rs1 + imm  (= ALU result)
    logic [31:0] PCBranchE;
    adder branchadd(PCE, ImmExtE, PCBranchE);
    mux2 #(32) pctargetmux(
        PCBranchE, ALUResultE,
        JumpE & (OpE == 7'b1100111),  // select ALU result only for JALR
        PCTargetE
    );

    assign PCSrcE = (BranchE & BranchOpE) | JumpE;

    // ---- EX/MEM pipeline register ----
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ALUResultM   <= 32'b0;  WriteDataM   <= 32'b0;  RdM          <= 5'b0;
            RegWriteM    <= 1'b0;   MemWriteM    <= 1'b0;   ResultSrcM   <= 1'b0;
            MemEnM       <= 1'b0;   CSRSrcM      <= 1'b0;
            Funct3M      <= 3'b0;   PCPlus4M     <= 32'b0;  CSRReadDataM <= 32'b0;
        end else begin
            ALUResultM   <= IEUResultE;  // link value (PC+4) or ALU result
            WriteDataM   <= SrcBE_pre;  // raw R2 value for stores (not immediate-muxed)
            RdM          <= RdE;
            RegWriteM    <= RegWriteE;
            MemWriteM    <= MemWriteE;
            ResultSrcM   <= ResultSrcE;
            MemEnM       <= MemEnE;
            CSRSrcM      <= CSRSrcE;
            Funct3M      <= Funct3E;
            PCPlus4M     <= PCPlus4E;
            CSRReadDataM <= CSRReadDataE;
        end
    end
endmodule
