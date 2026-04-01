// alu.sv
// 32-bit ALU supporting RV32I + M-extension multiply
// kacassidy@hmc.edu 2025

module alu (
    input  logic [31:0] SrcA, SrcB,
    input  logic [1:0]  ALUControl,
    input  logic [2:0]  Funct3,
    input  logic        Funct7b5,
    input  logic [6:0]  Funct7,
    input  logic        LUI,
    output logic [31:0] ALUResult,
    output logic [31:0] IEUAdr       // address output (= Sum)
);
    logic [31:0] CondInvb, Sum, SLT, SLTU;
    logic        Sub, ALUOp, ForceSub;
    logic        Overflow, Neg, LT;
    logic [2:0]  ALUFunct;
    logic [63:0] MulResult;
    logic        isMul;

    assign {Sub, ALUOp} = ALUControl;
    assign isMul        = (Funct7 == 7'b0000001) & ALUOp;

    // Force subtraction for SLT/SLTI (Funct3 = 010)
    assign ForceSub = Sub | (ALUOp & (Funct3 == 3'b010));

    assign CondInvb = ForceSub ? ~SrcB : SrcB;
    assign Sum      = SrcA + CondInvb + {{31{1'b0}}, ForceSub};
    assign SLTU     = {31'b0, (SrcA < SrcB)};
    assign IEUAdr   = Sum;

    assign Overflow = (SrcA[31] ^ SrcB[31]) & (SrcA[31] ^ Sum[31]);
    assign Neg      = Sum[31];
    assign LT       = Neg ^ Overflow;
    assign SLT      = {31'b0, LT};
    assign ALUFunct  = Funct3 & {3{ALUOp}};

    // Multiply (RV32M)
    always_comb
        case (Funct3)
            3'b000: MulResult = $signed({{1{SrcA[31]}}, SrcA}) * $signed({{1{SrcB[31]}}, SrcB}); // MUL
            3'b001: MulResult = $signed({{1{SrcA[31]}}, SrcA}) * $signed({{1{SrcB[31]}}, SrcB}); // MULH
            3'b010: MulResult = $signed({{1{SrcA[31]}}, SrcA}) * $signed({1'b0, SrcB});           // MULHSU
            3'b011: MulResult = {1'b0, SrcA} * {1'b0, SrcB};                                     // MULHU
            default: MulResult = 64'b0;
        endcase

    always_comb begin
        if (LUI)       ALUResult = SrcB;
        else if (isMul)
            case (Funct3)
                3'b000:  ALUResult = MulResult[31:0];   // MUL  → lower 32 bits
                default: ALUResult = MulResult[63:32];  // MULH/MULHSU/MULHU → upper 32 bits
            endcase
        else
            case (ALUFunct)
                3'b000: ALUResult = Sum;
                3'b001: ALUResult = SrcA << SrcB[4:0];
                3'b010: ALUResult = SLT;
                3'b011: ALUResult = SLTU;
                3'b100: ALUResult = SrcA ^ SrcB;
                3'b101: ALUResult = Funct7b5 ? ($signed(SrcA) >>> SrcB[4:0]) : (SrcA >> SrcB[4:0]);
                3'b110: ALUResult = SrcA | SrcB;
                3'b111: ALUResult = SrcA & SrcB;
                default: ALUResult = 32'bx;
            endcase
    end
endmodule
