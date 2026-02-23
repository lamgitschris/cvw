// riscvsingle.sv
// RISC-V single-cycle processor
// David_Harris@hmc.edu 2020

module alu(
        input   logic [31:0]    SrcA, SrcB,
        input   logic [1:0]     ALUControl,
        input   logic [2:0]     Funct3,
        input   logic [6:0]     Funct7,
        output  logic [31:0]    ALUResult, IEUAdr
    );

    logic [31:0] CondInvb, Sum, SLT;
    logic ALUOp, Sub, Overflow, Neg, LT;
    logic [2:0] ALUFunct;

    // Added logic
    logic [4:0]  shamt;
    logic [31:0] SLTU;

    assign shamt = SrcB[4:0];
    assign SLTU  = {31'b0, (SrcA < SrcB)}; // unsigned compare
    // Added logic

    assign {Sub, ALUOp} = ALUControl;

    // Add or subtract
    assign CondInvb = Sub ? ~SrcB : SrcB;
    assign Sum = SrcA + CondInvb + {{(31){1'b0}}, Sub};
    assign IEUAdr = Sum; // Send this out to IFU and LSU

    // Set less than based on subtraction result
    assign Overflow = (SrcA[31] ^ SrcB[31]) & (SrcA[31] ^ Sum[31]);
    assign Neg = Sum[31];
    assign LT = Neg ^ Overflow;
    assign SLT = {31'b0, LT};
    assign ALUFunct = Funct3 & {3{ALUOp}}; // Force ALUFunct to 0 to Add when ALUOp = 0

    always_comb begin
        case (ALUFunct)
            3'b000: ALUResult = Sum;                  // add or sub
            3'b001: ALUResult = SrcA << shamt;        // sll / slli
            3'b010: ALUResult = SLT;                  // slt (signed)
            3'b011: ALUResult = SLTU;                 // sltu / sltiu
            3'b101: begin                             // srl/sra + srli/srai
                if (Funct7[5]) ALUResult = $signed(SrcA) >>> shamt; // sra / srai
                else           ALUResult = SrcA >> shamt;           // srl / srli
            end
            3'b110: ALUResult = SrcA | SrcB;          // or
            3'b111: ALUResult = SrcA & SrcB;          // and
            default: ALUResult = 'x;
        endcase
    end
endmodule
