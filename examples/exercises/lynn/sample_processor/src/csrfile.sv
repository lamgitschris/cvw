module csrfile (
    input  logic        clk,
    input  logic        reset,
    input  logic [11:0] csradr,
    output logic [31:0] csrreaddata,
    output logic [63:0] TimeCounter
);

    logic [63:0] time_cnt;
    logic [63:0] instret;

    always_comb begin
        case (csradr)
            12'hC00, 12'hC01: csrreaddata = time_cnt[31:0];
            12'hC02:          csrreaddata = instret[31:0];
            12'hC80, 12'hC81: csrreaddata = time_cnt[63:32];
            12'hC82:          csrreaddata = instret[63:32];
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
            instret  <= instret + 64'd1;
        end
    end

endmodule
