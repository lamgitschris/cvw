// lsu.sv
// Load/Store Unit
//
// Spans the Memory and Writeback pipeline stages (LSU blue box in block diagram).
//
// Memory:   byte-enable generation for stores, load data alignment, DTIM interface
// Writeback: selects result written back to the register file

module lsu (
    input  logic        clk, reset,
    // From IEU EX/MEM register
    input  logic [31:0] ALUResultM, WriteDataM,
    input  logic [4:0]  RdM,
    input  logic        RegWriteM, MemWriteM, ResultSrcM, MemEnM, CSRSrcM,
    input  logic [2:0]  Funct3M,
    input  logic [31:0] CSRReadDataM,
    // DTIM interface
    input  logic [31:0] ReadData,
    output logic [31:0] IEUAdr,
    output logic [31:0] WriteData,
    output logic        MemEn, WriteEn,
    output logic [3:0]  WriteByteEn,
    // To IEU regfile (writeback)
    output logic        RegWriteW,
    output logic [4:0]  RdW,
    output logic [31:0] ResultW,
    // MEM-stage ALU result for forwarding back to IEU
    output logic [31:0] IEUResultM
);
    // Memory address is the ALU result; forward raw — DMEM wrapping and MMIO
    // interception are handled at the top level (riscvpipe.sv)
    assign IEUAdr    = ALUResultM;
    assign MemEn     = MemEnM;
    // Forward the actual MEM-stage value for ALU/CSR producers.
    // Loads still rely on the load-use stall, so forwarding ReadData is not needed here.
    assign IEUResultM = CSRSrcM ? CSRReadDataM : ALUResultM;
    // ----------------------------------------------------------------
    // Store byte enables and write data replication
    // ----------------------------------------------------------------
    always_comb
        if (MemWriteM)
            case (Funct3M[1:0])
                2'b00: begin                              // SB
                    WriteByteEn = 4'b0001 << ALUResultM[1:0];
                    WriteData   = {4{WriteDataM[7:0]}};
                end
                2'b01: begin                              // SH
                    WriteByteEn = ALUResultM[1] ? 4'b1100 : 4'b0011;
                    WriteData   = {2{WriteDataM[15:0]}};
                end
                default: begin                            // SW
                    WriteByteEn = 4'b1111;
                    WriteData   = WriteDataM;
                end
            endcase
        else begin
            WriteByteEn = 4'b0000;
            WriteData   = WriteDataM;
        end

    assign WriteEn = |WriteByteEn;

    // ----------------------------------------------------------------
    // Load data alignment
    // ----------------------------------------------------------------
    logic [7:0]  ByteVal;
    logic [15:0] HalfVal;
    logic [31:0] AlignedData;

    assign ByteVal = 8'(ReadData  >> (ALUResultM[1:0] * 8));
    assign HalfVal = 16'(ReadData >> (ALUResultM[1]   * 16));

    always_comb
        case (Funct3M)
            3'b000: AlignedData = {{24{ByteVal[7]}},  ByteVal};   // LB  (sign-extend)
            3'b001: AlignedData = {{16{HalfVal[15]}}, HalfVal};   // LH  (sign-extend)
            3'b100: AlignedData = {24'b0, ByteVal};               // LBU (zero-extend)
            3'b101: AlignedData = {16'b0, HalfVal};               // LHU (zero-extend)
            default: AlignedData = ReadData;                      // LW
        endcase

    // ----------------------------------------------------------------
    // MEM/WB pipeline register
    // ----------------------------------------------------------------
    logic [31:0] ALUResultW, ReadDataW, CSRReadDataW;
    logic        ResultSrcW, CSRSrcW;

    always_ff @(posedge clk or posedge reset)
        if (reset) begin
            ALUResultW   <= '0;  ReadDataW    <= '0;  RdW      <= '0;
            RegWriteW    <= '0;  ResultSrcW   <= '0;  CSRSrcW  <= '0;
            CSRReadDataW <= '0;
        end else begin
            ALUResultW   <= ALUResultM;
            ReadDataW    <= AlignedData;
            RdW          <= RdM;
            RegWriteW    <= RegWriteM;
            ResultSrcW   <= ResultSrcM;
            CSRSrcW      <= CSRSrcM;
            CSRReadDataW <= CSRReadDataM;
        end

    // ----------------------------------------------------------------
    // Writeback result mux
    // Priority: CSR read data > memory load data > ALU result
    // ----------------------------------------------------------------
    logic [31:0] ALUorMem;
    assign ALUorMem = ResultSrcW ? ReadDataW    : ALUResultW;
    assign ResultW  = CSRSrcW   ? CSRReadDataW : ALUorMem;

endmodule
