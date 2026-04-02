// alu.sv
// 32-bit ALU — supports all RV32I arithmetic and logic operations

module alu (
    input  logic [31:0] srca, srcb,
    input  logic [1:0]  alucontrol,   // {sub, aluop}
    input  logic [2:0]  funct3,
    input  logic        funct7b5,     // instr[30]: distinguishes SUB/SRA from ADD/SRL
    input  logic        lui,          // pass srcb straight through (LUI)
    output logic [31:0] aluresult
);
    logic [31:0] condinvb, sum, slt, sltu;
    logic        sub, aluop, forcesub;
    logic        overflow, neg, lt;
    logic [2:0]  alufunct;

    assign {sub, aluop} = alucontrol;

    // SLT/SLTI also need a subtraction to evaluate signed less-than
    assign forcesub = sub | (aluop & (funct3 == 3'b010));
    assign condinvb = forcesub ? ~srcb : srcb;
    assign sum      = srca + condinvb + {31'b0, forcesub};

    // Signed comparison via overflow-corrected sign bit of difference
    assign overflow = (srca[31] ^ srcb[31]) & (srca[31] ^ sum[31]);
    assign neg      = sum[31];
    assign lt       = neg ^ overflow;
    assign slt      = {31'b0, lt};
    assign sltu     = {31'b0, srca < srcb};

    // Mask funct3 to zero when aluop=0 (non-R/I ops), forcing the add path
    assign alufunct = funct3 & {3{aluop}};

    always_comb
        if (lui)
            aluresult = srcb;                               // LUI: pass immediate
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
