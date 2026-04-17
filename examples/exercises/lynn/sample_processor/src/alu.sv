// alu.sv
// 32-bit ALU — supports RV32I arithmetic/logic operations + Zmmul multiply

module alu (
    input  logic [31:0] srca, srcb,
    input  logic [2:0]  alucontrol,   // 000=force add, 001=I-type, 010=Zmmul, 011=R-type
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    input  logic        lui,
    output logic [31:0] aluresult
);

    logic [31:0] condinvb, sum, slt, sltu;
    logic        sub;
    logic        overflow, neg, lt;
    logic [4:0]  shamt;

    // One shared multiplier for all Zmmul ops
    logic signed [32:0] mul_a, mul_b;
    logic signed [65:0] mul_p;

    assign shamt = srcb[4:0];

    // SUB only for R-type subtract
    assign sub = (alucontrol == 3'b011) && (funct3 == 3'b000) && funct7[5];

    assign condinvb = sub ? ~srcb : srcb;
    assign sum      = srca + condinvb + {31'b0, sub};

    assign overflow = (srca[31] ^ condinvb[31]) & (srca[31] ^ sum[31]);
    assign neg      = sum[31];
    assign lt       = neg ^ overflow;
    assign slt      = {31'b0, ($signed(srca) < $signed(srcb))};
    assign sltu     = {31'b0, (srca < srcb)};

    //   mul    : low 32 bits only, signedness does not matter
    //   mulh   : signed x signed
    //   mulhsu : signed x unsigned
    //   mulhu  : unsigned x unsigned
    always_comb begin
        unique case (funct3)
            3'b001: begin // mulh
                mul_a = {srca[31], srca};
                mul_b = {srcb[31], srcb};
            end
            3'b010: begin // mulhsu
                mul_a = {srca[31], srca};
                mul_b = {1'b0, srcb};
            end
            3'b011: begin // mulhu
                mul_a = {1'b0, srca};
                mul_b = {1'b0, srcb};
            end
            default: begin // mul
                mul_a = {srca[31], srca};
                mul_b = {srcb[31], srcb};
            end
        endcase
    end

    assign mul_p = mul_a * mul_b;

    always_comb begin
        if (lui) begin
            aluresult = srcb;
        end else begin
            case (alucontrol)
                3'b000: begin
                    // force add path
                    aluresult = sum;
                end

                3'b001, 3'b011: begin
                    // I-type ALU and normal R-type ALU
                    case (funct3)
                        3'b000: aluresult = sum;                       // add/addi/sub
                        3'b001: aluresult = srca << shamt;             // sll/slli
                        3'b010: aluresult = slt;                       // slt/slti
                        3'b011: aluresult = sltu;                      // sltu/sltiu
                        3'b100: aluresult = srca ^ srcb;               // xor/xori
                        3'b101: begin
                            if (funct7[5]) aluresult = $signed(srca) >>> shamt; // sra/srai
                            else           aluresult = srca >> shamt;            // srl/srli
                        end
                        3'b110: aluresult = srca | srcb;               // or/ori
                        3'b111: aluresult = srca & srcb;               // and/andi
                        default: aluresult = 32'bx;
                    endcase
                end

                3'b010: begin
                    // Zmmul using one shared multiplier
                    case (funct3)
                        3'b000: aluresult = mul_p[31:0];   // mul
                        3'b001: aluresult = mul_p[63:32];  // mulh
                        3'b010: aluresult = mul_p[63:32];  // mulhsu
                        3'b011: aluresult = mul_p[63:32];  // mulhu
                        default: aluresult = 32'bx;
                    endcase
                end

                default: aluresult = 32'bx;
            endcase
        end
    end

endmodule
