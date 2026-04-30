// csrfile.sv
// Christian LamAlvarez and Anirudh Gupta
// CSR file for RV32I + Zmmul multiply instructions; supports time and instret CSRs


module csrfile (
    input  logic        clk,
    input  logic        reset,
    input  logic [11:0] csradr,
    input  logic        ValidM,
    input  logic        RetireW,
    output logic [31:0] csrreaddata,
    output logic [63:0] TimeCounter
);

    logic [63:0] time_cnt;
    logic [63:0] instret;
    logic [63:0] instret_visible;

    // CSR reads occur before writeback completes, so the raw instret register can be slightly behind.
    // Use a visible instret value that also accounts for the older valid instructions currently in MEM/WB.
    assign instret_visible = instret + {{63{1'b0}}, ValidM} + {{63{1'b0}}, RetireW};

    // Only the counters needed by this design are implemented. Everything else reads as zero.
    always_comb begin
        case (csradr)
            12'hC00, 12'hC01: csrreaddata = time_cnt[31:0];
            12'hC02:          csrreaddata = instret_visible[31:0];
            12'hC80, 12'hC81: csrreaddata = time_cnt[63:32];
            12'hC82:          csrreaddata = instret_visible[63:32];
            default:          csrreaddata = 32'b0;
        endcase
    end

    assign TimeCounter = time_cnt;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            time_cnt <= 64'b0;
            instret  <= 64'b0;
        end else begin
            time_cnt <= time_cnt + 64'd1;
            if (RetireW)
                instret <= instret + 64'd1;
        end
    end

endmodule
