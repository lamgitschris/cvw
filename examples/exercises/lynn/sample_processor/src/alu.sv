// riscvsingle.sv
// RISC-V single-cycle processor
// David_Harris@hmc.edu 2020

module alu(
        input   logic [31:0]    SrcA, SrcB,
        input   logic [2:0]     ALUControl,
        input   logic [2:0]     Funct3,
        input   logic [6:0]     Funct7,
        output  logic [31:0]    ALUResult, IEUAdr
    );

    logic [31:0] CondInvb, Sum, SLT;
    logic Overflow, Neg, LT;
    logic [2:0] ALUMode;
    logic [2:0] ALUFunct;
    logic [63:0] MulUU;
    logic signed [63:0] MulSS;
    logic signed [63:0] MulSU;
    logic Sub;

    // Added logic
    logic [4:0]  shamt;
    logic [31:0] SLTU;

    assign Sub = (ALUMode == 3'b011) && (Funct3 == 3'b000) && Funct7[5];
    assign shamt = SrcB[4:0];
    assign SLTU  = {31'b0, (SrcA < SrcB)}; // unsigned compare
    // Added logic

    assign ALUMode = ALUControl;
    assign ALUFunct = Funct3;

    assign MulUU = {32'b0, SrcA} * {32'b0, SrcB};

    assign MulSS = $signed({{32{SrcA[31]}}, SrcA}) *
                $signed({{32{SrcB[31]}}, SrcB});

    assign MulSU = $signed({{32{SrcA[31]}}, SrcA}) *
                $signed({32'b0, SrcB});

    // Add or subtract
    assign CondInvb = Sub ? ~SrcB : SrcB;
    assign Sum = SrcA + CondInvb + {{(31){1'b0}}, Sub};
    assign IEUAdr = Sum; // Send this out to IFU and LSU

    // Set less than based on subtraction result
    assign Overflow = (SrcA[31] ^ SrcB[31]) & (SrcA[31] ^ Sum[31]);
    assign Neg = Sum[31];
    assign LT = Neg ^ Overflow;
    assign SLT = {31'b0, LT};

    always_comb begin
        case (ALUMode)

            3'b000: begin
                ALUResult = Sum;   // force add
            end

            3'b001, 3'b011: begin
                case (ALUFunct)
                    3'b000: ALUResult = Sum;                  // add/sub
                    3'b001: ALUResult = SrcA << shamt;        // sll / slli
                    3'b010: ALUResult = SLT;                  // slt / slti
                    3'b011: ALUResult = SLTU;                 // sltu / sltiu
                    3'b100: ALUResult = SrcA ^ SrcB;          // xor / xori
                    3'b101: begin
                        if (Funct7[5]) ALUResult = $signed(SrcA) >>> shamt;
                        else           ALUResult = SrcA >> shamt;
                    end
                    3'b110: ALUResult = SrcA | SrcB;          // or / ori
                    3'b111: ALUResult = SrcA & SrcB;          // and / andi
                    default: ALUResult = 32'bx;
                endcase
            end

            3'b010: begin
                case (ALUFunct)
                    3'b000: ALUResult = MulSS[31:0];   // mul
                    3'b001: ALUResult = MulSS[63:32];  // mulh
                    3'b010: ALUResult = MulSU[63:32];  // mulhsu
                    3'b011: ALUResult = MulUU[63:32];  // mulhu
                    default: ALUResult = 32'bx;
                endcase
            end

            default: ALUResult = 32'bx;
        endcase
    end
endmodule
