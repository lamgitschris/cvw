// decode_stage.sv
// Decode stage — register file reads, control decode, and ID/EX pipeline register
// kacassidy@hmc.edu 2025
//
// Reads two source registers, generates the immediate, and decodes all control
// signals.  Registers everything into the ID/EX pipeline register at the end of
// the cycle.  FlushE inserts a bubble (NOP) on branch/jump or load-use stall.

module decode_stage (
    input  logic        clk, reset,
    input  logic        FlushE,       // flush ID/EX register
    // Inputs from IF/ID register
    input  logic [31:0] InstrD, PCD, PCPlus4D,
    // Write-back port (register file write from WB stage)
    input  logic        RegWriteW,
    input  logic [4:0]  RdW,
    input  logic [31:0] ResultW,

    // ID/EX pipeline register outputs — data
    output logic [31:0] RD1E, RD2E,
    output logic [31:0] PCE, PCPlus4E,
    output logic [31:0] ImmExtE,
    output logic [4:0]  Rs1E, Rs2E, RdE,
    // ID/EX pipeline register outputs — control
    output logic        RegWriteE,
    output logic [1:0]  ALUSrcE,
    output logic        ALUOpE,
    output logic [1:0]  ALUControlE,
    output logic        ALUResultSrcE,
    output logic        MemWriteE,
    output logic        ResultSrcE,
    output logic        BranchE,
    output logic        JumpE,
    output logic        MemEnE,
    output logic        LUIE,
    output logic        CSRSrcE,
    // Instruction fields forwarded to EX (needed by ALU / CSR)
    output logic [2:0]  Funct3E,
    output logic        Funct7b5E,
    output logic [6:0]  Funct7E,
    output logic [11:0] CSRAdrE,
    output logic [6:0]  OpE
);
    // ---- Register file ----
    logic [31:0] RD1D, RD2D;
    regfile rf(
        .clk,
        .WE3(RegWriteW), .A3(RdW),    .WD3(ResultW),
        .A1(InstrD[19:15]),            .RD1(RD1D),
        .A2(InstrD[24:20]),            .RD2(RD2D)
    );

    // ---- Immediate generator ----
    logic [31:0] ImmExtD;
    logic [2:0]  ImmSrcD;
    extend ext(.Instr(InstrD[31:7]), .ImmSrc(ImmSrcD), .ImmExt(ImmExtD));

    // ---- Control decoders ----
    logic        RegWriteD, ALUOpD, ALUResultSrcD;
    logic [1:0]  ALUSrcD, ALUControlD;
    logic        MemWriteD, ResultSrcD, BranchD, JumpD, MemEnD, LUID;

    maindec md(
        .Op(InstrD[6:0]),
        .RegWrite(RegWriteD), .ImmSrc(ImmSrcD),
        .ALUSrc(ALUSrcD),     .ALUOp(ALUOpD),
        .ALUResultSrc(ALUResultSrcD),
        .MemWrite(MemWriteD), .ResultSrc(ResultSrcD),
        .Branch(BranchD),     .Jump(JumpD),
        .MemEn(MemEnD),       .LUI(LUID)
    );

    aludec ad(
        .ALUOp(ALUOpD),
        .Funct3(InstrD[14:12]),
        .Funct7b5(InstrD[30]),
        .OpBit5(InstrD[5]),
        .ALUControl(ALUControlD)
    );

    // CSRSrc: CSRRS/CSRRCI instructions (Op=1110011, Funct3=010)
    logic CSRSrcD;
    assign CSRSrcD = (InstrD[6:0] == 7'b1110011) & (InstrD[14:12] == 3'b010);

    // ---- ID/EX pipeline register ----
    always_ff @(posedge clk or posedge reset) begin
        if (reset || FlushE) begin
            // Bubble: zero out all data and deassert all control signals
            RD1E <= 32'b0;    RD2E <= 32'b0;
            PCE  <= 32'b0;    PCPlus4E <= 32'b0;    ImmExtE <= 32'b0;
            Rs1E <= 5'b0;     Rs2E <= 5'b0;          RdE <= 5'b0;
            RegWriteE <= 1'b0;  ALUSrcE <= 2'b0;
            ALUOpE <= 1'b0;     ALUControlE <= 2'b0;
            ALUResultSrcE <= 1'b0;
            MemWriteE <= 1'b0;  ResultSrcE <= 1'b0;
            BranchE <= 1'b0;    JumpE <= 1'b0;    MemEnE <= 1'b0;
            LUIE <= 1'b0;       CSRSrcE <= 1'b0;
            Funct3E <= 3'b0;    Funct7b5E <= 1'b0;
            Funct7E <= 7'b0;    CSRAdrE <= 12'b0;  OpE <= 7'b0;
        end else begin
            RD1E <= RD1D;     RD2E <= RD2D;
            PCE  <= PCD;      PCPlus4E <= PCPlus4D;  ImmExtE <= ImmExtD;
            Rs1E <= InstrD[19:15];
            Rs2E <= InstrD[24:20];
            RdE  <= InstrD[11:7];
            RegWriteE     <= RegWriteD;
            ALUSrcE       <= ALUSrcD;
            ALUOpE        <= ALUOpD;
            ALUControlE   <= ALUControlD;
            ALUResultSrcE <= ALUResultSrcD;
            MemWriteE     <= MemWriteD;
            ResultSrcE    <= ResultSrcD;
            BranchE       <= BranchD;
            JumpE         <= JumpD;
            MemEnE        <= MemEnD;
            LUIE          <= LUID;
            CSRSrcE       <= CSRSrcD;
            Funct3E       <= InstrD[14:12];
            Funct7b5E     <= InstrD[30];
            // Funct7 only meaningful for R-type; zero otherwise to avoid spurious MUL detection
            Funct7E       <= (InstrD[6:0] == 7'b0110011) ? InstrD[31:25] : 7'b0;
            CSRAdrE       <= InstrD[31:20];
            OpE           <= InstrD[6:0];
        end
    end
endmodule
