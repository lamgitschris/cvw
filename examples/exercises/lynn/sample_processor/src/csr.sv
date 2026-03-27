module csr(
        input   logic           clk,
        input   logic           reset,
        input   logic           InstrRetired,
        input logic Hpm3Event,
        input logic Hpm4Event,
        input logic Hpm5Event,
        input logic Hpm6Event,
        input logic Hpm7Event,
        input logic Hpm8Event,
        input logic Hpm9Event,
        input logic Hpm10Event,
        input   logic [11:0]    CsrAddr,
        output  logic [31:0]    CsrReadData,
        output logic [63:0] TimeCounter
    );

    logic [63:0] cycle_counter;
    logic [63:0] time_counter;
    logic [63:0] instret_counter;
    logic [63:0] hpm_counter [3:31];
    integer i;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cycle_counter   <= 64'd0;
            time_counter    <= 64'd0;
            instret_counter <= 64'd0;
            // reset storage
            for (i = 3; i <= 31; i = i + 1)
                hpm_counter[i] <= 64'd0;
        end else begin
            cycle_counter <= cycle_counter + 64'd1;
            time_counter  <= time_counter + 64'd1;
            if (Hpm3Event)  hpm_counter[3]  <= hpm_counter[3]  + 64'd1;
            if (Hpm4Event)  hpm_counter[4]  <= hpm_counter[4]  + 64'd1;
            if (Hpm5Event)  hpm_counter[5]  <= hpm_counter[5]  + 64'd1;
            if (Hpm6Event)  hpm_counter[6]  <= hpm_counter[6]  + 64'd1;
            if (Hpm7Event)  hpm_counter[7]  <= hpm_counter[7]  + 64'd1;
            if (Hpm8Event)  hpm_counter[8]  <= hpm_counter[8]  + 64'd1;
            if (Hpm9Event)  hpm_counter[9]  <= hpm_counter[9]  + 64'd1;
            if (Hpm10Event) hpm_counter[10] <= hpm_counter[10] + 64'd1;
            if (InstrRetired)
                instret_counter <= instret_counter + 64'd1;
        end
    end

    always_comb begin
        case (CsrAddr)
            12'hC00: CsrReadData = cycle_counter[31:0];     // cycle
            12'hC01: CsrReadData = time_counter[31:0];      // time
            12'hC02: CsrReadData = instret_counter[31:0];   // instret

            12'hC80: CsrReadData = cycle_counter[63:32];    // cycleh
            12'hC81: CsrReadData = time_counter[63:32];     // timeh
            12'hC82: CsrReadData = instret_counter[63:32];  // instreth

            // hpm event signals
            12'hC03: CsrReadData = hpm_counter[3][31:0];
            12'hC04: CsrReadData = hpm_counter[4][31:0];
            12'hC05: CsrReadData = hpm_counter[5][31:0];
            12'hC06: CsrReadData = hpm_counter[6][31:0];
            12'hC07: CsrReadData = hpm_counter[7][31:0];
            12'hC08: CsrReadData = hpm_counter[8][31:0];
            12'hC09: CsrReadData = hpm_counter[9][31:0];
            12'hC0A: CsrReadData = hpm_counter[10][31:0];

            12'hC83: CsrReadData = hpm_counter[3][63:32];
            12'hC84: CsrReadData = hpm_counter[4][63:32];
            12'hC85: CsrReadData = hpm_counter[5][63:32];
            12'hC86: CsrReadData = hpm_counter[6][63:32];
            12'hC87: CsrReadData = hpm_counter[7][63:32];
            12'hC88: CsrReadData = hpm_counter[8][63:32];
            12'hC89: CsrReadData = hpm_counter[9][63:32];
            12'hC8A: CsrReadData = hpm_counter[10][63:32];

            default: CsrReadData = 32'h00000000;
        endcase
    end
    assign TimeCounter = time_counter;
endmodule
