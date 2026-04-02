// alu.sv
// 32-bit ALU supporting RV32I
// kacassidy@hmc.edu 2025

module alu (
    input  logic [31:0] srca, srcb,
    input  logic [1:0]  alucontrol,
    input  logic [2:0]  funct3,
    input  logic        funct7b5,
    input  logic        lui,
    output logic [31:0] aluresult
);
    logic [31:0] condinvb, sum, slt, sltu;
    logic        sub, aluop, forcesub;
    logic        overflow, neg, lt;
    logic [2:0]  alufunct;

    assign {sub, aluop} = alucontrol;

    // Force subtraction path for SLT/SLTI (funct3=010)
    assign forcesub = sub | (aluop & (funct3 == 3'b010));
    assign condinvb = forcesub ? ~srcb : srcb;
    assign sum      = srca + condinvb + {31'b0, forcesub};

    // Signed less-than via overflow-corrected subtraction result
    assign overflow = (srca[31] ^ srcb[31]) & (srca[31] ^ sum[31]);
    assign neg      = sum[31];
    assign lt       = neg ^ overflow;
    assign slt      = {31'b0, lt};
    assign sltu     = {31'b0, (srca < srcb)};

    // When aluop=0 (non-R/I-ALU ops) mask funct3 to force adder path
    assign alufunct = funct3 & {3{aluop}};

    always_comb begin
        if (lui) aluresult = srcb;  // LUI: pass upper immediate through
        else
            case (alufunct)
                3'b000: aluresult = sum;
                3'b001: aluresult = srca << srcb[4:0];
                3'b010: aluresult = slt;
                3'b011: aluresult = sltu;
                3'b100: aluresult = srca ^ srcb;
                3'b101: aluresult = funct7b5 ? ($signed(srca) >>> srcb[4:0])
                                              : (srca >> srcb[4:0]);
                3'b110: aluresult = srca | srcb;
                3'b111: aluresult = srca & srcb;
                default: aluresult = 32'bx;
            endcase
    end
endmodule
