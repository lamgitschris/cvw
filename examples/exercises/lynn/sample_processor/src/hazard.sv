// hazard.sv
// Christian LamAlvarez and Anirudh Gupta
// Hazard detection unit (forwarding handled directly inside IEU)


module hazard (
    input  logic [4:0]  RdE,
    input  logic        ResultSrcE,      // 1 when EX instruction is a load
    input  logic [4:0]  Rs1D, Rs2D,      // source registers of ID-stage instruction
    input  logic        PCSrcE,          // 1 on taken branch or any jump
    output logic        StallF, StallD,
    output logic        FlushD, FlushE
);
    logic LWStall;

    // A load result is not available in time for the following instruction to use it in EX.
    // Stall fetch and decode for one cycle, and insert a bubble into EX until the load data is ready.
    assign LWStall = ResultSrcE & ((RdE == Rs1D) | (RdE == Rs2D));

    assign StallF = LWStall;
    assign StallD = LWStall;

    // When a branch is taken or a jump occurs, the instruction currently in decode is on the wrong path and must be flushed.
    assign FlushD = PCSrcE;
    assign FlushE = LWStall | PCSrcE;

endmodule
