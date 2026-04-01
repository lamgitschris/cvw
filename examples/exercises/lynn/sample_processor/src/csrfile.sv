// csrfile.sv
// CSR performance counters: cycle, instret, and hpmcounter3-10
// kacassidy@hmc.edu 2025
//
// Note: In the pipeline, CSRAdr/Op/Funct3 arrive from the EX stage
// (one cycle after decode).  BranchOp is passed as 0 because the
// branch outcome is not known until EX; branch-taken counts are
// therefore approximate, which is acceptable for profiling.

module csrfile (
    input  logic        clk, reset,
    input  logic [11:0] CSRAdr,
    input  logic [6:0]  Op,
    input  logic [2:0]  Funct3,
    input  logic        Funct7b5,
    input  logic        BranchOp,
    output logic [31:0] CSRReadData
);
    logic [63:0] cycle, instret;
    logic [63:0] hpm3, hpm4, hpm5, hpm6, hpm7, hpm8, hpm9, hpm10;

    // Instruction-type classification for hpm counters
    logic isAdd, isBranch, isBranchTaken, isLoad, isStore, isJump, isIALU, isRtype;

    assign isAdd         = ((Op == 7'b0110011) & (Funct3 == 3'b000) & ~Funct7b5) |
                           ((Op == 7'b0010011) & (Funct3 == 3'b000));
    assign isBranch      = (Op == 7'b1100011);
    assign isBranchTaken = isBranch & BranchOp;
    assign isLoad        = (Op == 7'b0000011);
    assign isStore       = (Op == 7'b0100011);
    assign isJump        = (Op == 7'b1101111) | (Op == 7'b1100111);
    assign isIALU        = (Op == 7'b0010011);
    assign isRtype       = (Op == 7'b0110011);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cycle   <= 64'b0;  instret <= 64'b0;
            hpm3    <= 64'b0;  hpm4    <= 64'b0;
            hpm5    <= 64'b0;  hpm6    <= 64'b0;
            hpm7    <= 64'b0;  hpm8    <= 64'b0;
            hpm9    <= 64'b0;  hpm10   <= 64'b0;
        end else begin
            cycle   <= cycle + 1;
            instret <= instret + 1;
            if (isAdd)         hpm3  <= hpm3  + 1;
            if (isBranch)      hpm4  <= hpm4  + 1;
            if (isBranchTaken) hpm5  <= hpm5  + 1;
            if (isLoad)        hpm6  <= hpm6  + 1;
            if (isStore)       hpm7  <= hpm7  + 1;
            if (isJump)        hpm8  <= hpm8  + 1;
            if (isIALU)        hpm9  <= hpm9  + 1;
            if (isRtype)       hpm10 <= hpm10 + 1;
        end
    end

    always_comb
        case (CSRAdr)
            12'hC00: CSRReadData = cycle[31:0];
            12'hC01: CSRReadData = cycle[31:0];    // rdtime aliases rdcycle
            12'hC02: CSRReadData = instret[31:0];
            12'hC80: CSRReadData = cycle[63:32];
            12'hC81: CSRReadData = cycle[63:32];
            12'hC82: CSRReadData = instret[63:32];
            12'hC03: CSRReadData = hpm3[31:0];    12'hC83: CSRReadData = hpm3[63:32];
            12'hC04: CSRReadData = hpm4[31:0];    12'hC84: CSRReadData = hpm4[63:32];
            12'hC05: CSRReadData = hpm5[31:0];    12'hC85: CSRReadData = hpm5[63:32];
            12'hC06: CSRReadData = hpm6[31:0];    12'hC86: CSRReadData = hpm6[63:32];
            12'hC07: CSRReadData = hpm7[31:0];    12'hC87: CSRReadData = hpm7[63:32];
            12'hC08: CSRReadData = hpm8[31:0];    12'hC88: CSRReadData = hpm8[63:32];
            12'hC09: CSRReadData = hpm9[31:0];    12'hC89: CSRReadData = hpm9[63:32];
            12'hC0A: CSRReadData = hpm10[31:0];   12'hC8A: CSRReadData = hpm10[63:32];
            default: CSRReadData = 32'b0;
        endcase
endmodule
