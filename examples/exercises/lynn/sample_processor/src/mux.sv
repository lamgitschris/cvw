// mux.sv
// Parameterized 2:1 and 3:1 multiplexers

module mux2 #(parameter WIDTH = 32) (
    input  logic [WIDTH-1:0] a, b,
    input  logic             sel,
    output logic [WIDTH-1:0] y
);
    assign y = sel ? b : a;
endmodule

module mux3 #(parameter WIDTH = 32) (
    input  logic [WIDTH-1:0] a, b, c,
    input  logic [1:0]       sel,
    output logic [WIDTH-1:0] y
);
    always_comb
        case (sel)
            2'b00:   y = a;
            2'b01:   y = b;
            2'b10:   y = c;
            default: y = a;
        endcase
endmodule
