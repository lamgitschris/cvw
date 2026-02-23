// riscvsingle.sv
// RISC-V single-cycle processor
// David_Harris@hmc.edu 2020
// Edited by
// Christian LamAlvarez
// clamalvarez@hmc.edu

module cmp(
        input   logic [31:0]    R1, R2,
        output  logic           Eq,
        output  logic           LT,     // signed less-than
        output  logic           LTU     // unsigned less-than
    );

    assign Eq  = (R1 == R2);
    assign LT  = ($signed(R1) < $signed(R2));
    assign LTU = (R1 < R2);
endmodule
