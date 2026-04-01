// writeback_stage.sv
// Writeback stage — selects the final result written back to the register file
// kacassidy@hmc.edu 2025
//
// Result priority (via muxes):
//   1. CSR read data   (csrrs/csrrci)
//   2. Memory read data (loads)
//   3. ALU/link result  (everything else)

module writeback_stage (
    input  logic [31:0] ALUResultW,
    input  logic [31:0] ReadDataW,
    input  logic        ResultSrcW,    // 1 = select memory read data
    input  logic        CSRSrcW,       // 1 = select CSR read data
    input  logic [31:0] CSRReadDataW,
    output logic [31:0] ResultW        // to register file write port and forwarding path
);
    logic [31:0] IEUorMemResult;

    mux2 #(32) resultmux(ALUResultW, ReadDataW,    ResultSrcW, IEUorMemResult);
    mux2 #(32) csrmux   (IEUorMemResult, CSRReadDataW, CSRSrcW,    ResultW);
endmodule
