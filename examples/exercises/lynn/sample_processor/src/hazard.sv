// hazard.sv
// Hazard detection unit — forwarding, load-use stall, branch/jump flush
// kacassidy@hmc.edu 2025
//
// Forwarding:
//   ForwardAE/ForwardBE select the EX-stage ALU inputs:
//     00 = register file (no hazard)
//     01 = WB-stage result
//     10 = MEM-stage result (takes priority; most recently written)
//
// Load-use stall:
//   If the EX-stage instruction is a load (ResultSrcM=1) and its destination
//   matches a source of the ID-stage instruction, stall IF and ID for one cycle
//   and inject a bubble into EX.
//
// Control hazard flush:
//   Branch/jump resolved in EX.  Flush the IF/ID register (FlushD) and the
//   ID/EX register (FlushE) to squash the two speculatively-fetched instructions.

module hazard (
    // EX-stage source registers
    input  logic [4:0]  Rs1E, Rs2E,
    // MEM- and WB-stage destination registers
    input  logic [4:0]  RdM, RdW,
    // Write enables
    input  logic        RegWriteM, RegWriteW,
    // Load signal: 1 when MEM-stage instruction reads memory
    input  logic        ResultSrcM,
    // ID-stage source registers (for load-use check)
    input  logic [4:0]  Rs1D, Rs2D,
    // EX-stage destination register (for load-use check)
    input  logic [4:0]  RdE,
    // Branch/jump taken flag from EX stage
    input  logic        PCSrcE,

    output logic [1:0]  ForwardAE, ForwardBE,
    output logic        StallF, StallD,
    output logic        FlushD, FlushE
);
    logic lwStall;

    // ---- Forwarding logic ----
    always_comb begin
        // SrcA forwarding
        if      (RegWriteM && (RdM != 0) && (RdM == Rs1E)) ForwardAE = 2'b10; // from MEM
        else if (RegWriteW && (RdW != 0) && (RdW == Rs1E)) ForwardAE = 2'b01; // from WB
        else                                                ForwardAE = 2'b00; // from regfile

        // SrcB forwarding (pre-immediate mux)
        if      (RegWriteM && (RdM != 0) && (RdM == Rs2E)) ForwardBE = 2'b10;
        else if (RegWriteW && (RdW != 0) && (RdW == Rs2E)) ForwardBE = 2'b01;
        else                                                ForwardBE = 2'b00;
    end

    // ---- Load-use stall ----
    assign lwStall = ResultSrcM & ((RdE == Rs1D) | (RdE == Rs2D));

    assign StallF = lwStall;
    assign StallD = lwStall;

    // ---- Flush logic ----
    assign FlushD = PCSrcE;             // squash instruction in IF on branch/jump
    assign FlushE = lwStall | PCSrcE;  // squash instruction in ID on stall or branch/jump
endmodule
