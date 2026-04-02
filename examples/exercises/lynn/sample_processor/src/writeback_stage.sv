// writeback_stage.sv
// Writeback stage — selects result written to register file
// kacassidy@hmc.edu 2025
//
// Priority (via muxes):
//   CSR read data  (csrrs/csrrci)
//   Memory data    (loads)
//   ALU result     (everything else, including JAL/JALR link = PC+4)

module writeback_stage (
    input  logic [31:0] aluresultw,
    input  logic [31:0] readdataw,
    input  logic        resultsrcw,
    input  logic        csrsrcw,
    input  logic [31:0] csrreaddataw,
    output logic [31:0] resultw
);
    logic [31:0] aluormem;
    mux2 #(32) resmux (aluresultw, readdataw,    resultsrcw, aluormem);
    mux2 #(32) csrmux (aluormem,   csrreaddataw, csrsrcw,    resultw);
endmodule
