// ifu.sv
// Instruction Fetch Unit — Fetch stage and IF/ID pipeline register
// kacassidy@hmc.edu 2025
//
// Responsibilities:
//   - Maintains the PC; supports stall (StallF) and branch/jump redirect (PCSrcE)
//   - Drives the instruction memory address
//   - Holds the IF/ID pipeline register (stallable + flushable)

module ifu (
    input  logic        clk, reset,
    // Hazard control
    input  logic        StallF,      // hold PC
    input  logic        StallD,      // hold IF/ID register
    input  logic        FlushD,      // flush IF/ID register (branch/jump taken)
    // Branch/jump target from EX stage
    input  logic        PCSrcE,
    input  logic [31:0] PCTargetE,
    // Instruction memory read data
    input  logic [31:0] InstrF,
    // To instruction memory
    output logic [31:0] PC,
    output logic [31:0] PCPlus4F,
    // IF/ID pipeline register outputs (to Decode stage)
    output logic [31:0] InstrD,
    output logic [31:0] PCD,
    output logic [31:0] PCPlus4D
);
    logic [31:0] PCF, PCNextF;
    logic [31:0] entry_addr;

    initial begin
        entry_addr = '0;
        void'($value$plusargs("ENTRY_ADDR=%h", entry_addr));
    end

    // PC register — stall holds, reset returns to entry address
    always_ff @(posedge clk or posedge reset) begin
        if (reset)        PCF <= entry_addr;
        else if (!StallF) PCF <= {PCNextF[31:2], 2'b0};  // force word-aligned
    end

    assign PC = PCF;

    adder        pcadd4(PCF, 32'd4, PCPlus4F);
    mux2 #(32)   pcmux(PCPlus4F, PCTargetE, PCSrcE, PCNextF);

    // IF/ID pipeline register — flush overrides stall
    always_ff @(posedge clk or posedge reset) begin
        if (reset || FlushD) begin
            InstrD   <= 32'b0;
            PCD      <= 32'b0;
            PCPlus4D <= 32'b0;
        end else if (!StallD) begin
            InstrD   <= InstrF;
            PCD      <= PCF;
            PCPlus4D <= PCPlus4F;
        end
        // else: hold (stall)
    end
endmodule
