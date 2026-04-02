// ifu.sv
// Instruction Fetch Unit
//
// Contains the fetch stage and IF/ID pipeline register.
// On a branch or jump (PCSrcE=1), redirects PC to PCTargetE.
// Stalls both the PC register and IF/ID register on a load-use hazard.
// Flushes the IF/ID register (inserts NOP) on a branch/jump taken.

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

    // Allow entry address override from simulation plusarg
    logic [31:0] entry_addr;
    initial begin
        entry_addr = '0;
        void'($value$plusargs("ENTRY_ADDR=%h", entry_addr));
    end

    // PC register
    always_ff @(posedge clk or posedge reset)
        if      (reset)   PCF <= entry_addr;
        else if (!StallF) PCF <= {PCNextF[31:2], 2'b0}; // keep word-aligned

    assign PC       = PCF;
    assign PCPlus4F = PCF + 32'd4;
    assign PCNextF  = PCSrcE ? PCTargetE : PCPlus4F;

    // IF/ID pipeline register — flush takes priority over stall
    always_ff @(posedge clk or posedge reset)
        if (reset || FlushD) begin
            InstrD   <= 32'b0;
            PCD      <= 32'b0;
            PCPlus4D <= 32'b0;
        end else if (!StallD) begin
            InstrD   <= Instr;
            PCD      <= PCF;
            PCPlus4D <= PCPlus4F;
        end
endmodule
