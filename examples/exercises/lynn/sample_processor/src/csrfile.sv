// csrfile.sv
// CSR file for Zicntr / Zihpm / basic Zicsr support.
//
// Implemented readable counters:
//   cycle/time/instret      at C00/C01/C02 and C80/C81/C82
//   hpmcounter3-10          at C03-C0A and C83-C8A
//
// Implemented writable CSR:
//   mscratch                at 340
//
// Supported CSR ops:
//   csrrw/csrrs/csrrc
//   csrrwi/csrrsi/csrrci
//
// Writes to read-only counters are ignored.

module csrfile (
    input  logic        clk,
    input  logic        reset,
    input  logic [11:0] csradr,

    // Current EX-stage instruction classification / CSR op info
    input  logic [6:0]  op,
    input  logic [2:0]  funct3,
    input  logic        funct7b5,
    input  logic        branchop,

    // CSR source operand info
    input  logic [31:0] rs1data,   // forwarded rs1 value for register CSR ops
    input  logic [4:0]  rs1addr,   // raw rs1 field; used as zimm for immediate CSR ops

    output logic [31:0] csrreaddata,
    output logic [63:0] TimeCounter
);

    logic [63:0] cycle, time_cnt, instret;
    logic [63:0] hpm3, hpm4, hpm5, hpm6, hpm7, hpm8, hpm9, hpm10;
    logic [31:0] mscratch;

    logic isAdd, isBranch, isBranchTaken, isLoad, isStore, isJump, isIALU, isRtype;

    logic [31:0] csr_rdata;
    logic [31:0] csr_wdata;
    logic [31:0] csr_src;
    logic        csr_we;

    // -----------------------------
    // HPM event classification
    // -----------------------------
    // hpm3 = ADD only (not ADDI)
    assign isAdd         = (op == 7'b0110011) && (funct3 == 3'b000) && ~funct7b5;
    assign isBranch      = (op == 7'b1100011);
    assign isBranchTaken = isBranch & branchop;
    assign isLoad        = (op == 7'b0000011);
    assign isStore       = (op == 7'b0100011);
    assign isJump        = (op == 7'b1101111) | (op == 7'b1100111);
    assign isIALU        = (op == 7'b0010011);
    assign isRtype       = (op == 7'b0110011);

    // CSR source:
    //   register forms  -> rs1data
    //   immediate forms -> zero-extended rs1 field (zimm)
    assign csr_src = funct3[2] ? {27'b0, rs1addr} : rs1data;

    // -----------------------------
    // CSR read mux
    // -----------------------------
    always_comb begin
        case (csradr)
            12'h340: csr_rdata = mscratch;

            12'hC00: csr_rdata = cycle[31:0];
            12'hC01: csr_rdata = time_cnt[31:0];
            12'hC02: csr_rdata = instret[31:0];

            12'hC80: csr_rdata = cycle[63:32];
            12'hC81: csr_rdata = time_cnt[63:32];
            12'hC82: csr_rdata = instret[63:32];

            12'hC03: csr_rdata = hpm3[31:0];
            12'hC04: csr_rdata = hpm4[31:0];
            12'hC05: csr_rdata = hpm5[31:0];
            12'hC06: csr_rdata = hpm6[31:0];
            12'hC07: csr_rdata = hpm7[31:0];
            12'hC08: csr_rdata = hpm8[31:0];
            12'hC09: csr_rdata = hpm9[31:0];
            12'hC0A: csr_rdata = hpm10[31:0];

            12'hC83: csr_rdata = hpm3[63:32];
            12'hC84: csr_rdata = hpm4[63:32];
            12'hC85: csr_rdata = hpm5[63:32];
            12'hC86: csr_rdata = hpm6[63:32];
            12'hC87: csr_rdata = hpm7[63:32];
            12'hC88: csr_rdata = hpm8[63:32];
            12'hC89: csr_rdata = hpm9[63:32];
            12'hC8A: csr_rdata = hpm10[63:32];

            default: csr_rdata = 32'b0;
        endcase
    end

    assign csrreaddata = csr_rdata;
    assign TimeCounter = time_cnt;

    // -----------------------------
    // CSR write decode
    // Only mscratch is writable here.
    // -----------------------------
    always_comb begin
        csr_we    = 1'b0;
        csr_wdata = csr_rdata;

        if ((op == 7'b1110011) && (csradr == 12'h340)) begin
            case (funct3)
                3'b001, 3'b101: begin
                    // csrrw / csrrwi
                    csr_we    = 1'b1;
                    csr_wdata = csr_src;
                end

                3'b010, 3'b110: begin
                    // csrrs / csrrsi
                    if (csr_src != 32'b0) begin
                        csr_we    = 1'b1;
                        csr_wdata = csr_rdata | csr_src;
                    end
                end

                3'b011, 3'b111: begin
                    // csrrc / csrrci
                    if (csr_src != 32'b0) begin
                        csr_we    = 1'b1;
                        csr_wdata = csr_rdata & ~csr_src;
                    end
                end

                default: begin
                    csr_we    = 1'b0;
                    csr_wdata = csr_rdata;
                end
            endcase
        end
    end

    // -----------------------------
    // Counter / CSR state update
    // -----------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cycle    <= 64'b0;
            time_cnt <= 64'b0;
            instret  <= 64'b0;

            hpm3     <= 64'b0;
            hpm4     <= 64'b0;
            hpm5     <= 64'b0;
            hpm6     <= 64'b0;
            hpm7     <= 64'b0;
            hpm8     <= 64'b0;
            hpm9     <= 64'b0;
            hpm10    <= 64'b0;

            mscratch <= 32'b0;
        end else begin
            cycle    <= cycle + 64'd1;
            time_cnt <= time_cnt + 64'd1;
            instret  <= instret + 64'd1;

            if (isAdd)         hpm3  <= hpm3  + 64'd1;
            if (isBranch)      hpm4  <= hpm4  + 64'd1;
            if (isBranchTaken) hpm5  <= hpm5  + 64'd1;
            if (isLoad)        hpm6  <= hpm6  + 64'd1;
            if (isStore)       hpm7  <= hpm7  + 64'd1;
            if (isJump)        hpm8  <= hpm8  + 64'd1;
            if (isIALU)        hpm9  <= hpm9  + 64'd1;
            if (isRtype)       hpm10 <= hpm10 + 64'd1;

            if (csr_we)
                mscratch <= csr_wdata;
        end
    end

endmodule
