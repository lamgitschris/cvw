// adder.sv
// 32-bit adder
// kacassidy@hmc.edu 2025

module adder (
    input  logic [31:0] a, b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule
