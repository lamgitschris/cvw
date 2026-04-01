// memory_stage.sv
// Memory stage — data memory interface, store byte-enable/replication,
//                load data alignment, and MEM/WB pipeline register
// kacassidy@hmc.edu 2025

module memory_stage (
    input  logic        clk, reset,
    // From EX/MEM pipeline register
    input  logic [31:0] ALUResultM,    // memory address (or ALU/link result)
    input  logic [31:0] WriteDataM,    // store data (raw R2 value from EX)
    input  logic [4:0]  RdM,
    input  logic        RegWriteM,
    input  logic        MemWriteM,
    input  logic        ResultSrcM,    // 1 = load instruction
    input  logic        MemEnM,
    input  logic        CSRSrcM,
    input  logic [2:0]  Funct3M,
    input  logic [31:0] PCPlus4M,
    input  logic [31:0] CSRReadDataM,
    // Data memory interface
    input  logic [31:0] ReadData,      // from data memory
    output logic [31:0] DataAdr,       // to data memory
    output logic [31:0] WriteData,     // byte-replicated store data
    output logic        MemEn,
    output logic        WriteEn,
    output logic [3:0]  WriteByteEn,

    // MEM/WB pipeline register outputs
    output logic [31:0] ALUResultW,
    output logic [31:0] ReadDataW,     // aligned load data
    output logic [4:0]  RdW,
    output logic        RegWriteW,
    output logic        ResultSrcW,
    output logic        CSRSrcW,
    output logic [31:0] PCPlus4W,
    output logic [31:0] CSRReadDataW,

    // Forwarding output — ALU result available to EX stage this cycle
    output logic [31:0] ResultM
);
    assign DataAdr = ALUResultM;
    assign MemEn   = MemEnM;
    assign ResultM = ALUResultM;  // forward ALU/link result (load data not yet available)

    // ---- Store byte-enable and write-data replication ----
    always_comb begin
        if (MemWriteM) begin
            case (Funct3M[1:0])
                2'b00: begin  // SB — replicate byte to all lanes; byte-enable selects correct lane
                    WriteByteEn = 4'b0001 << ALUResultM[1:0];
                    WriteData   = {4{WriteDataM[7:0]}};
                end
                2'b01: begin  // SH — replicate halfword; byte-enable selects upper or lower half
                    WriteByteEn = ALUResultM[1] ? 4'b1100 : 4'b0011;
                    WriteData   = {2{WriteDataM[15:0]}};
                end
                default: begin  // SW
                    WriteByteEn = 4'b1111;
                    WriteData   = WriteDataM;
                end
            endcase
        end else begin
            WriteByteEn = 4'b0000;
            WriteData   = WriteDataM;
        end
    end
    assign WriteEn = |WriteByteEn;

    // ---- Load data alignment ----
    // Shift the correct byte/halfword to bits [7:0] or [15:0] then sign/zero-extend
    logic [7:0]  ByteVal;
    logic [15:0] HalfVal;
    logic [31:0] SelectedData;

    assign ByteVal = 8'(ReadData >> (ALUResultM[1:0] * 8));
    assign HalfVal = 16'(ReadData >> (ALUResultM[1]  * 16));

    always_comb
        case (Funct3M)
            3'b000: SelectedData = {{24{ByteVal[7]}}, ByteVal};   // LB  (sign-extend)
            3'b001: SelectedData = {{16{HalfVal[15]}}, HalfVal};  // LH  (sign-extend)
            3'b100: SelectedData = {24'b0, ByteVal};              // LBU (zero-extend)
            3'b101: SelectedData = {16'b0, HalfVal};              // LHU (zero-extend)
            default: SelectedData = ReadData;                     // LW
        endcase

    // ---- MEM/WB pipeline register ----
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ALUResultW   <= 32'b0;  ReadDataW    <= 32'b0;  RdW          <= 5'b0;
            RegWriteW    <= 1'b0;   ResultSrcW   <= 1'b0;   CSRSrcW      <= 1'b0;
            PCPlus4W     <= 32'b0;  CSRReadDataW <= 32'b0;
        end else begin
            ALUResultW   <= ALUResultM;
            ReadDataW    <= SelectedData;
            RdW          <= RdM;
            RegWriteW    <= RegWriteM;
            ResultSrcW   <= ResultSrcM;
            CSRSrcW      <= CSRSrcM;
            PCPlus4W     <= PCPlus4M;
            CSRReadDataW <= CSRReadDataM;
        end
    end
endmodule
