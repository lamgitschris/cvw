// ifu.sv
// Christian LamAlvarez and Anirudh Gupta
// Instruction Fetch Unit: maintains the PC, fetches instructions from IROM, and implements IF/ID pipeline register


module ifu (
    input  logic        clk, reset,
    input  logic        StallF, StallD, FlushD,
    input  logic        PCSrcE,
    input  logic [31:0] PCTargetE,
    input  logic [31:0] Instr,        // from instruction memory (IROM)
    output logic [31:0] PC,           // to instruction memory
    output logic [31:0] InstrD, PCD, PCPlus4D
);
    logic [31:0] PCF, PCNextF, PCPlus4F;

    logic [31:0] entry_addr;
    initial begin
        entry_addr = '0;
        void'($value$plusargs("ENTRY_ADDR=%h", entry_addr));
    end

    // Hold PC on a fetch stall; otherwise step to PC+4 or the resolved target.
    always_ff @(posedge clk or posedge reset)
        if      (reset)   PCF <= entry_addr;
        else if (!StallF) PCF <= {PCNextF[31:2], 2'b0}; // keep word-aligned

    assign PC       = PCF;
    assign PCPlus4F = PCF + 32'd4;
    assign PCNextF  = PCSrcE ? PCTargetE : PCPlus4F;

    // IF/ID register. Flush takes priority so wrong-path instructions are removed
    // even if decode is otherwise stalled.
    always_ff @(posedge clk or posedge reset)
        if (reset) begin
            InstrD   <= 32'b0;
            PCD      <= 32'b0;
            PCPlus4D <= 32'b0;
        end else if (FlushD) begin
            InstrD   <= 32'b0;
            PCD      <= 32'b0;
            PCPlus4D <= 32'b0;
        end else if (!StallD) begin
            InstrD   <= Instr;
            PCD      <= PCF;
            PCPlus4D <= PCPlus4F;
        end
endmodule
