// lsu.sv
// Load/Store Unit glue logic for sub-word accesses

module lsu(
    input  logic [31:0] Adr,           // byte address
    input  logic [31:0] StoreDataIn,    // raw rs2
    input  logic [31:0] ReadDataIn,     // 32-bit word from memory

    input  logic [2:0]  LoadType,       // from controller
    input  logic [1:0]  StoreType,      // from controller
    input  logic        StoreEn,        // 1 when instruction is a store

    output logic [31:0] StoreDataOut,   // lane-shifted write data
    output logic [3:0]  WriteByteEnOut, // strobes
    output logic [31:0] LoadDataOut     // extracted/extended load data
);

    // Encodings must match controller.sv
    localparam logic [2:0]
        LD_LB  = 3'd0,
        LD_LH  = 3'd1,
        LD_LW  = 3'd2,
        LD_LBU = 3'd3,
        LD_LHU = 3'd4;

    localparam logic [1:0]
        ST_SB = 2'd0,
        ST_SH = 2'd1,
        ST_SW = 2'd2;

    logic [1:0] a;
    logic [31:0] r;
    logic [7:0]  b;
    logic [15:0] h;

    assign a = Adr[1:0];
    assign r = ReadDataIn;

    // Extract selected byte/half from the returned 32-bit word
    logic [31:0] r_byte_shift;
    logic [31:0] r_half_shift;

    assign r_byte_shift = r >> (8*a);
    assign r_half_shift = r >> (16*a[1]);

    assign b = r_byte_shift[7:0];
    assign h = r_half_shift[15:0];

    // LOAD path: pick, then sign/zero extend
    always_comb begin
        case (LoadType)
            LD_LB:  LoadDataOut = {{24{b[7]}}, b};
            LD_LBU: LoadDataOut = {24'b0, b};
            LD_LH:  LoadDataOut = {{16{h[15]}}, h};
            LD_LHU: LoadDataOut = {16'b0, h};
            LD_LW:  LoadDataOut = r;
            default: LoadDataOut = r;
        endcase
    end

    // STORE path: byte enables + lane placement
    always_comb begin
        // defaults
        WriteByteEnOut = 4'b0000;
        StoreDataOut   = StoreDataIn;

        if (StoreEn) begin
            case (StoreType)
                ST_SB: begin
                    WriteByteEnOut = (4'b0001 << a);
                    StoreDataOut   = {24'b0, StoreDataIn[7:0]} << (8*a);
                end
                ST_SH: begin
                    WriteByteEnOut = (a[1] ? 4'b1100 : 4'b0011);
                    StoreDataOut   = {16'b0, StoreDataIn[15:0]} << (16*a[1]);
                end
                ST_SW: begin
                    WriteByteEnOut = 4'b1111;
                    StoreDataOut   = StoreDataIn;
                end
                default: begin
                    WriteByteEnOut = 4'b1111;
                    StoreDataOut   = StoreDataIn;
                end
            endcase
        end
    end

endmodule
