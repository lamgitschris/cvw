// riscvsingle.sv
// RISC-V single-cycle processor
// David_Harris@hmc.edu 2020

`include "parameters.svh"

module controller(
        input   logic [6:0]   Op,
        input   logic         Eq,
        input   logic         LT,
        input   logic         LTU,
        input   logic [2:0]   Funct3,
        input   logic [6:0]   Funct7,
        output  logic         ALUResultSrc,
        output  logic [2:0]   ResultSrc,
        output  logic [3:0]   WriteByteEn,
        output  logic         PCSrc,
        output  logic         RegWrite,
        output  logic [1:0]   ALUSrc,
        output  logic [2:0]   ImmSrc,
        output  logic [2:0]   ALUControl,
        output  logic         MemEn,
        output logic [2:0] BranchType,
        output logic [2:0] LoadType,
        output logic [1:0] StoreType,
        output logic [1:0] JumpType
    `ifdef DEBUG
        , input   logic [31:0]  insn_debug
    `endif
    );

    // BranchType encodings
    localparam logic [2:0]
        BR_BEQ  = 3'd0,
        BR_BNE  = 3'd1,
        BR_BLT  = 3'd2,
        BR_BGE  = 3'd3,
        BR_BLTU = 3'd4,
        BR_BGEU = 3'd5;

    // LoadType encodings
    logic [2:0]
        LD_LB  = 3'd0,
        LD_LH  = 3'd1,
        LD_LW  = 3'd2,
        LD_LBU = 3'd3,
        LD_LHU = 3'd4;

    // StoreType encodings
    logic [1:0]
        ST_SB = 2'd0,
        ST_SH = 2'd1,
        ST_SW = 2'd2;

    // JumpType encodings
    logic [1:0]
        J_NONE = 2'd0,
        J_JAL  = 2'd1,
        J_JALR = 2'd2;

    logic Branch, Jump;
    logic Sub, ALUOp;
    logic MemWrite;
    logic [14:0] controls;

    // Main decoder
    always_comb begin
        // Defaults (safe / do-nothing)
        controls   = 15'b0;
        BranchType = BR_BEQ;
        LoadType   = LD_LW;
        StoreType  = ST_SW;
        JumpType   = J_NONE;

        case (Op)
            // lw
            7'b0000011: begin
                controls = 15'b1_000_01_0_0_0_001_0_0_1;
                ALUControl = 3'b000; // force add
                // Phase 0: classify load by funct3 (only lw used now, but we map the rest)
                case (Funct3)
                    3'b000: LoadType = LD_LB;
                    3'b001: LoadType = LD_LH;
                    3'b010: LoadType = LD_LW;
                    3'b100: LoadType = LD_LBU;
                    3'b101: LoadType = LD_LHU;
                    default: LoadType = LD_LW; // keep safe default
                endcase
            end

            // sw
            7'b0100011: begin
                controls = 15'b0_001_01_0_0_1_000_0_0_1;
                ALUControl = 3'b000; // force add
                case (Funct3)
                    3'b000: StoreType = ST_SB;
                    3'b001: StoreType = ST_SH;
                    3'b010: StoreType = ST_SW;
                    default: StoreType = ST_SW;
                endcase
            end

            // R-type
            7'b0110011: begin
                controls = 15'b1_xxx_00_1_0_0_000_0_0_0;
                if (Funct7 == 7'b0000001)
                    ALUControl = 3'b010; // mul-family
                else
                    ALUControl = 3'b011; // normal R-type ALU
            end

            // I-type ALU
            7'b0010011: begin
                controls = 15'b1_000_01_1_0_0_000_0_0_0;
                ALUControl = 3'b001; // normal funct3 decode
            end

            // branches
            7'b1100011: begin
                controls = 15'b0_010_11_0_0_0_000_1_0_0;
                ALUControl = 3'b000; // normal funct3 decode
                case (Funct3)
                    3'b000: BranchType = BR_BEQ;
                    3'b001: BranchType = BR_BNE;
                    3'b100: BranchType = BR_BLT;
                    3'b101: BranchType = BR_BGE;
                    3'b110: BranchType = BR_BLTU;
                    3'b111: BranchType = BR_BGEU;
                    default: BranchType = BR_BEQ;
                endcase
            end

            // jal
            7'b1101111: begin
                controls = 15'b1_011_11_0_1_0_000_0_1_0;
                JumpType = J_JAL;
            end

            // jalr
            7'b1100111: begin
                // rd = PC+4, PC = (rs1 + immI) & ~1
                // Only valid encoding is funct3=000, but we’ll just treat others as default for now
                controls = 15'b1_000_01_0_1_0_000_0_1_0; // RegWrite, ImmSrc=I, ALUSrc=01 (A=R1, B=Imm), add, write PC+4, Jump=1
                ALUControl = 3'b000; // force add
                JumpType  = J_JALR;
            end

            // lui
            7'b0110111: begin
                // rd = immU
                controls = 15'b1_100_00_0_0_0_010_0_0_0; // ResultSrc=10 selects ImmExt
                JumpType  = J_NONE;
            end

            // auipc
            7'b0010111: begin
                // rd = PC + immU
                controls = 15'b1_100_11_0_0_0_000_0_0_0; // ALUSrc=11 => SrcA=PC, SrcB=ImmExt
                ALUControl = 3'b000; // force add
                JumpType  = J_NONE;
            end

            // csrrs rd, csr, x0  (read-only CSR access for this lab)
            7'b1110011: begin
                if (Funct3 == 3'b010) begin
                    controls = 15'b1_000_00_0_0_0_100_0_0_0; // write back CSR read data
                end
            end

            default: begin
                ALUControl = 3'b000;
                `ifdef DEBUG
                    controls = 15'bx_xxx_xx_x_x_x_xxx_x_x_x;
                    if ((insn_debug !== 'x)) begin
                    $display("Instruction not implemented: %h", insn_debug);
                    $finish(-1);
                    end
                `else
                    controls = 15'b0;
                `endif
            end
        endcase
    end

    assign {RegWrite, ImmSrc, ALUSrc, ALUOp, ALUResultSrc, MemWrite,
    ResultSrc, Branch, Jump, MemEn} = controls;

    // PCSrc logic
    logic BranchTaken;
    always_comb begin
        BranchTaken = 1'b0;

        // only meaningful when Op is branch, but safe regardless
        case (Funct3)
            3'b000: BranchTaken =  Eq;      // beq
            3'b001: BranchTaken = ~Eq;      // bne
            3'b100: BranchTaken =  LT;      // blt  (signed)
            3'b101: BranchTaken = ~LT;      // bge  (signed)
            3'b110: BranchTaken =  LTU;     // bltu (unsigned)
            3'b111: BranchTaken = ~LTU;     // bgeu (unsigned)
            default: BranchTaken = 1'b0;
        endcase
    end
    assign PCSrc = Jump | (Branch & BranchTaken);

    // MemWrite logic
    // Raw store enable (LSU will compute real byte strobes)
    assign WriteByteEn = MemWrite ? 4'b1111 : 4'b0000;
endmodule
