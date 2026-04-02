// csrfile.sv
// Read-only CSR counters: cycle and instret
//
// CoreMark uses rdcycle / rdcycleh for its timing measurements.
// instret is included as it is architecturally required by RV32I.

module csrfile (
    input  logic        clk, reset,
    input  logic [11:0] csradr,
    output logic [31:0] csrreaddata
);
    logic [63:0] cycle, instret;

    always_ff @(posedge clk or posedge reset)
        if (reset) begin
            cycle   <= '0;
            instret <= '0;
        end else begin
            cycle   <= cycle   + 1;
            instret <= instret + 1;
        end

    always_comb
        case (csradr)
            12'hC00: csrreaddata = cycle[31:0];     // rdcycle
            12'hC01: csrreaddata = cycle[31:0];     // rdtime   (alias)
            12'hC02: csrreaddata = instret[31:0];   // rdinstret
            12'hC80: csrreaddata = cycle[63:32];    // rdcycleh
            12'hC81: csrreaddata = cycle[63:32];    // rdtimeh  (alias)
            12'hC82: csrreaddata = instret[63:32];  // rdinstreth
            default: csrreaddata = 32'b0;
        endcase
endmodule
