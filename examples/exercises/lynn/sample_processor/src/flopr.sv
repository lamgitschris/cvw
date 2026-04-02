// flopr.sv
// Parameterized resettable flip-flop
// kacassidy@hmc.edu 2025

module flopr #(parameter WIDTH = 32, parameter DEFAULT = 0) (
    input  logic               clk, reset,
    input  logic [WIDTH-1:0]   d,
    output logic [WIDTH-1:0]   q
);
    always_ff @(posedge clk or posedge reset)
        if (reset) q <= DEFAULT;
        else       q <= d;
endmodule
