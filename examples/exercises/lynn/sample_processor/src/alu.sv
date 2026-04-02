// alu.sv
// 32-bit ALU — supports all RV32I arithmetic/logic operations + Zmmul multiply

module alu (
    input  logic [31:0] srca, srcb,
    input  logic [2:0]  alucontrol,   // 000=force add, 001=I-type, 010=Zmmul, 011=R-type
    input  logic [2:0]  funct3,
    input  logic        funct7b5,     // instr[30]: distinguishes SUB/SRA from ADD/SRL
    input  logic        lui,          // pass srcb straight through (LUI)
    output logic [31:0] aluresult
);
    logic [31:0] condinvb, sum, slt, sltu;
    logic        sub, aluop, forcesub;
    logic        overflow, neg, lt;
    logic [2:0]  alufunct;

    // Zmmul 64-bit products
    logic [63:0] MulUU;
    logic signed [63:0] MulSS, MulSU;
    assign MulUU = {32'b0, srca} * {32'b0, srcb};
    assign MulSS = $signed({{32{srca[31]}}, srca}) * $signed({{32{srcb[31]}}, srcb});
    assign MulSU = $signed({{32{srca[31]}}, srca}) * $signed({32'b0, srcb});

    // SUB only in R-type mode (011) when funct7b5 is set and funct3==000
    assign sub      = (alucontrol == 3'b011) & (funct3 == 3'b000) & funct7b5;
    // aluop=1 when using funct3 (I-type=001 or R-type=011), i.e. alucontrol[0]
    assign aluop    = alucontrol[0];
    // SLT/SLTI also need a subtraction to evaluate signed less-than
    assign forcesub = sub | (aluop & (funct3 == 3'b010));
    assign condinvb = forcesub ? ~srcb : srcb;
    assign sum      = srca + condinvb + {31'b0, forcesub};

    assign overflow = (srca[31] ^ srcb[31]) & (srca[31] ^ sum[31]);
    assign neg      = sum[31];
    assign lt       = neg ^ overflow;
    assign slt      = {31'b0, lt};
    assign sltu     = {31'b0, srca < srcb};

    // Mask funct3 to zero when aluop=0 (force-add path)
    assign alufunct = funct3 & {3{aluop}};

    always_comb
        if (lui)
            aluresult = srcb;                               // LUI: pass immediate
        else if (alucontrol == 3'b010)
            // Zmmul
            case (funct3)
                3'b000: aluresult = MulSS[31:0];            // mul
                3'b001: aluresult = MulSS[63:32];           // mulh
                3'b010: aluresult = MulSU[63:32];           // mulhsu
                3'b011: aluresult = MulUU[63:32];           // mulhu
                default: aluresult = 32'bx;
            endcase
        else
            case (alufunct)
                3'b000: aluresult = sum;                    // ADD / SUB
                3'b001: aluresult = srca << srcb[4:0];      // SLL
                3'b010: aluresult = slt;                    // SLT
                3'b011: aluresult = sltu;                   // SLTU
                3'b100: aluresult = srca ^ srcb;            // XOR
                3'b101: aluresult = funct7b5                // SRL / SRA
                                    ? $signed(srca) >>> srcb[4:0]
                                    : srca          >>  srcb[4:0];
                3'b110: aluresult = srca | srcb;            // OR
                3'b111: aluresult = srca & srcb;            // AND
                default: aluresult = 32'bx;
            endcase

endmodule
