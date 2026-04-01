// flopr.sv
// Parameterized resettable flip-flops
// kacassidy@hmc.edu 2025

// Simple reset flip-flop
module flopr #(parameter WIDTH = 32, parameter DEFAULT = 0) (
    input  logic               clk, reset,
    input  logic [WIDTH-1:0]   D,
    output logic [WIDTH-1:0]   Q
);
    always_ff @(posedge clk, posedge reset)
        if (reset) Q <= DEFAULT;
        else       Q <= D;
endmodule

// Reset + enable flip-flop (used for stall control)
module flopenr #(parameter WIDTH = 32, parameter DEFAULT = 0) (
    input  logic               clk, reset, en,
    input  logic [WIDTH-1:0]   D,
    output logic [WIDTH-1:0]   Q
);
    always_ff @(posedge clk, posedge reset)
        if (reset)   Q <= DEFAULT;
        else if (en) Q <= D;
endmodule
