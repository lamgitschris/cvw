// hazard.sv
// Hazard detection and forwarding unit

module hazard (
    input  logic [4:0]  Rs1E, Rs2E, RdE,
    input  logic        ResultSrcE,      // 1 when EX instruction is a load
    input  logic [4:0]  RdM, RdW,
    input  logic        RegWriteM, RegWriteW,
    input  logic [4:0]  Rs1D, Rs2D,      // source registers of ID-stage instruction
    input  logic        PCSrcE,          // 1 on taken branch or any jump
    output logic [1:0]  ForwardAE, ForwardBE,
    output logic        StallF, StallD,
    output logic        FlushD, FlushE
);
    logic LWStall;

    // Forwarding: MEM result has priority over WB
    always_comb begin
        ForwardAE = (RegWriteM && RdM != '0 && RdM == Rs1E) ? 2'b10 :
                    (RegWriteW && RdW != '0 && RdW == Rs1E) ? 2'b01 : 2'b00;

        ForwardBE = (RegWriteM && RdM != '0 && RdM == Rs2E) ? 2'b10 :
                    (RegWriteW && RdW != '0 && RdW == Rs2E) ? 2'b01 : 2'b00;
    end

    // Load-use stall: freeze IF and ID, flush EX bubble for one cycle
    assign LWStall = ResultSrcE & ((RdE == Rs1D) | (RdE == Rs2D));

    assign StallF = LWStall;
    assign StallD = LWStall;
    assign FlushD = PCSrcE;
    assign FlushE = LWStall | PCSrcE;

endmodule
