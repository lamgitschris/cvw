// mux.sv
// Parameterized 2:1 and 3:1 multiplexers
// kacassidy@hmc.edu 2025

module mux2 #(parameter WIDTH = 32) (
    input  logic [WIDTH-1:0] A, B,
    input  logic             select,
    output logic [WIDTH-1:0] result
);
    assign result = select ? B : A;
endmodule

module mux3 #(parameter WIDTH = 32) (
    input  logic [WIDTH-1:0] A, B, C,
    input  logic [1:0]       select,
    output logic [WIDTH-1:0] result
);
    always_comb
        case (select)
            2'b00:   result = A;
            2'b01:   result = B;
            2'b10:   result = C;
            default: result = A;
        endcase
endmodule
