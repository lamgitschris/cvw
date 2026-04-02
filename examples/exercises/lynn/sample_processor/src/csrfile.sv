// csrfile.sv
// CSR performance counters: cycle, time, instret, and hpmcounter3-10
//
// cycle/time/instret increment every clock.
// hpm3-10 are event counters driven by instruction classification signals
// from the EX stage (op, funct3, funct7b5, branchop).
//
// TimeCounter is exposed as a 64-bit output for MMIO timer reads
// at addresses 0x0200BFF8 (time low) and 0x0200BFFC (time high).

module csrfile (
    input  logic        clk, reset,
    input  logic [11:0] csradr,
    // Instruction classification signals from EX stage
    input  logic [6:0]  op,
    input  logic [2:0]  funct3,
    input  logic        funct7b5,
    input  logic        branchop,       // branch condition true (from cmp unit)
    output logic [31:0] csrreaddata,
    output logic [63:0] TimeCounter     // exposed for MMIO reads at 0x0200BFF8/BFFC
);
    logic [63:0] cycle, time_cnt, instret;
    logic [63:0] hpm3, hpm4, hpm5, hpm6, hpm7, hpm8, hpm9, hpm10;

    // Instruction-type classification (matches old single-cycle hpm events)
    logic isAdd, isBranch, isBranchTaken, isLoad, isStore, isJump, isIALU, isRtype;

    assign isAdd         = ((op == 7'b0110011) & (funct3 == 3'b000) & ~funct7b5) |
                           ((op == 7'b0010011) & (funct3 == 3'b000));
    assign isBranch      = (op == 7'b1100011);
    assign isBranchTaken = isBranch & branchop;
    assign isLoad        = (op == 7'b0000011);
    assign isStore       = (op == 7'b0100011);
    assign isJump        = (op == 7'b1101111) | (op == 7'b1100111);
    assign isIALU        = (op == 7'b0010011);
    assign isRtype       = (op == 7'b0110011);

    always_ff @(posedge clk or posedge reset)
        if (reset) begin
            cycle    <= '0;  time_cnt <= '0;  instret <= '0;
            hpm3     <= '0;  hpm4     <= '0;  hpm5    <= '0;  hpm6  <= '0;
            hpm7     <= '0;  hpm8     <= '0;  hpm9    <= '0;  hpm10 <= '0;
        end else begin
            cycle    <= cycle    + 1;
            time_cnt <= time_cnt + 1;
            instret  <= instret  + 1;
            if (isAdd)         hpm3  <= hpm3  + 1;
            if (isBranch)      hpm4  <= hpm4  + 1;
            if (isBranchTaken) hpm5  <= hpm5  + 1;
            if (isLoad)        hpm6  <= hpm6  + 1;
            if (isStore)       hpm7  <= hpm7  + 1;
            if (isJump)        hpm8  <= hpm8  + 1;
            if (isIALU)        hpm9  <= hpm9  + 1;
            if (isRtype)       hpm10 <= hpm10 + 1;
        end

    assign TimeCounter = time_cnt;

    always_comb
        case (csradr)
            12'hC00: csrreaddata = cycle[31:0];
            12'hC01: csrreaddata = time_cnt[31:0];      // rdtime
            12'hC02: csrreaddata = instret[31:0];
            12'hC80: csrreaddata = cycle[63:32];
            12'hC81: csrreaddata = time_cnt[63:32];     // rdtimeh
            12'hC82: csrreaddata = instret[63:32];
            12'hC03: csrreaddata = hpm3[31:0];    12'hC83: csrreaddata = hpm3[63:32];
            12'hC04: csrreaddata = hpm4[31:0];    12'hC84: csrreaddata = hpm4[63:32];
            12'hC05: csrreaddata = hpm5[31:0];    12'hC85: csrreaddata = hpm5[63:32];
            12'hC06: csrreaddata = hpm6[31:0];    12'hC86: csrreaddata = hpm6[63:32];
            12'hC07: csrreaddata = hpm7[31:0];    12'hC87: csrreaddata = hpm7[63:32];
            12'hC08: csrreaddata = hpm8[31:0];    12'hC88: csrreaddata = hpm8[63:32];
            12'hC09: csrreaddata = hpm9[31:0];    12'hC89: csrreaddata = hpm9[63:32];
            12'hC0A: csrreaddata = hpm10[31:0];   12'hC8A: csrreaddata = hpm10[63:32];
            default: csrreaddata = 32'b0;
        endcase

endmodule
