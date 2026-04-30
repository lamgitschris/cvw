// alu.sv
// Christian LamAlvarez and Anirudh Gupta
// 32-bit ALU for RV32I + Zmmul multiply instructions


module alu (
    input  logic [31:0] srca, srcb,
    input  logic [2:0]  alucontrol,   // 000=force add, 001=I-type, 010=Zmmul, 011=R-type
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    input  logic        lui,
    output logic [31:0] aluresult
);

    // Shared arithmetic signals used by add/sub and set-less-than operations.
    logic [31:0] condinvb, sum, slt, sltu;
    logic        sub;
    logic        overflow, neg, lt;
    logic [4:0]  shamt;

    // One multiplier handles all four Zmmul variants.
    logic signed [32:0] mul_a, mul_b;
    logic signed [65:0] mul_p;

    assign shamt = srcb[4:0];

    // Subtraction is only selected for the R-type SUB encoding.
    assign sub = (alucontrol == 3'b011) && (funct3 == 3'b000) && funct7[5];

    // The adder is shared by ADD, SUB, address generation, and the ALU compare path.
    assign condinvb = sub ? ~srcb : srcb;
    assign sum      = srca + condinvb + {31'b0, sub};

    assign overflow = (srca[31] ^ condinvb[31]) & (srca[31] ^ sum[31]);
    assign neg      = sum[31];
    assign lt       = neg ^ overflow;
    assign slt      = {31'b0, ($signed(srca) < $signed(srcb))};
    assign sltu     = {31'b0, (srca < srcb)};

    // Pick operand signedness based on the multiply variant.
    always_comb begin
        unique case (funct3)
            3'b001: begin // mulh: signed x signed
                mul_a = {srca[31], srca};
                mul_b = {srcb[31], srcb};
            end
            3'b010: begin // mulhsu: signed x unsigned
                mul_a = {srca[31], srca};
                mul_b = {1'b0, srcb};
            end
            3'b011: begin // mulhu: unsigned x unsigned
                mul_a = {1'b0, srca};
                mul_b = {1'b0, srcb};
            end
            default: begin // mul: low 32 bits only
                mul_a = {srca[31], srca};
                mul_b = {srcb[31], srcb};
            end
        endcase
    end

    assign mul_p = mul_a * mul_b;

    always_comb begin
        if (lui) begin
            // LUI writes the upper-immediate value directly.
            aluresult = srcb;
        end else begin
            case (alucontrol)
                3'b000: begin
                    // Force-add path for loads, stores, branches, jalr, and auipc.
                    aluresult = sum;
                end

                3'b001, 3'b011: begin
                    // I-type ALU ops and normal R-type ops share this decode.
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
                    // High-half multiply variants all read the same upper product bits.
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
