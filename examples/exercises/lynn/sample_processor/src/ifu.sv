// ifu.sv
// Instruction Fetch Unit — Fetch stage and IF/ID pipeline register
// kacassidy@hmc.edu 2025

module ifu (
    input  logic        clk, reset,
    input  logic        stallf, stalld, flushd,
    input  logic        pcsrce,
    input  logic [31:0] pctargete,
    input  logic [31:0] instrf,       // from instruction memory
    output logic [31:0] pc,           // to instruction memory
    // IF/ID register outputs
    output logic [31:0] instrd,
    output logic [31:0] pcd,
    output logic [31:0] pcplus4d
);
    logic [31:0] pcf, pcnextf, pcplus4f;

    logic [31:0] entry_addr;
    initial begin
        entry_addr = '0;
        void'($value$plusargs("ENTRY_ADDR=%h", entry_addr));
    end

    // PC register — holds on stall, resets to entry address
    always_ff @(posedge clk or posedge reset) begin
        if (reset)        pcf <= entry_addr;
        else if (!stallf) pcf <= {pcnextf[31:2], 2'b0}; // force word-aligned
    end

    assign pc       = pcf;
    adder      pcadd4  (pcf, 32'd4, pcplus4f);
    mux2 #(32) pcmux   (pcplus4f, pctargete, pcsrce, pcnextf);

    // IF/ID pipeline register — flush overrides stall
    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushd) begin
            instrd   <= 32'b0;
            pcd      <= 32'b0;
            pcplus4d <= 32'b0;
        end else if (!stalld) begin
            instrd   <= instrf;
            pcd      <= pcf;
            pcplus4d <= pcplus4f;
        end
    end
endmodule
