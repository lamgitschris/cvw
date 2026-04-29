// hazard.sv
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

    // Load-use stall: freeze IF and ID, flush EX bubble for one cycle
    assign LWStall = ResultSrcE & ((RdE == Rs1D) | (RdE == Rs2D));

    assign StallF = LWStall;
    assign StallD = LWStall;
    assign FlushD = PCSrcE;
    assign FlushE = LWStall | PCSrcE;

endmodule
