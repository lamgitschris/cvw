// csrfile.sv
// Counts clock cycles and instructions retired; needed for CoreMark/Zicntr.
// instret is stored as a true retirement counter, but CSR reads in EX must
// see older valid instructions currently in MEM and WB as already retired.

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

    // CSR reads happen in EX. Older valid instructions in MEM and WB should
    // already be visible in instret even though the stored counter is only
    // updated once an instruction actually retires in WB.
    assign instret_visible = instret + {{63{1'b0}}, ValidM} + {{63{1'b0}}, RetireW};

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
