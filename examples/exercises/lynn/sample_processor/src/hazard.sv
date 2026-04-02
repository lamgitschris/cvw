// hazard.sv
// Hazard detection: forwarding, load-use stall, branch/jump flush
// kacassidy@hmc.edu 2025
//
// Forwarding mux select (ForwardAE / ForwardBE):
//   2'b00 = register file value (no hazard)
//   2'b01 = WB-stage result
//   2'b10 = MEM-stage result (priority — most recently written)
//
// Load-use stall: when a load is in EX and the next instruction (in ID)
//   needs its result, stall IF+ID and flush EX for one cycle.
//   Uses resultsrce (EX-stage signal) — NOT the MEM-stage version.
//
// Control hazard flush: branches/jumps resolved in EX.
//   Flush IF/ID (flushd) and ID/EX (flushe) to squash speculative fetches.

module hazard (
    input  logic [4:0]  rs1e, rs2e,       // EX-stage source registers
    input  logic [4:0]  rdm, rdw,         // MEM/WB destination registers
    input  logic        regwritem, regwritew,
    input  logic        resultsrce,        // 1 when EX-stage instruction is a load
    input  logic [4:0]  rs1d, rs2d,       // ID-stage source registers
    input  logic [4:0]  rde,              // EX-stage destination register
    input  logic        pcsrce,           // branch/jump taken

    output logic [1:0]  forwardae, forwardbe,
    output logic        stallf, stalld,
    output logic        flushd, flushe
);
    logic lwstall;

    // Forwarding — MEM takes priority over WB
    always_comb begin
        forwardae = (regwritem && rdm != 0 && rdm == rs1e) ? 2'b10 :
                    (regwritew && rdw != 0 && rdw == rs1e) ? 2'b01 : 2'b00;

        forwardbe = (regwritem && rdm != 0 && rdm == rs2e) ? 2'b10 :
                    (regwritew && rdw != 0 && rdw == rs2e) ? 2'b01 : 2'b00;
    end

    // Load-use stall — check EX-stage load signal against ID-stage sources
    assign lwstall = resultsrce & ((rde == rs1d) | (rde == rs2d));

    assign stallf = lwstall;
    assign stalld = lwstall;
    assign flushd = pcsrce;
    assign flushe = lwstall | pcsrce;
endmodule
