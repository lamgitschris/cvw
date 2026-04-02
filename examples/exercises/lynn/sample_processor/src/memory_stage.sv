// memory_stage.sv
// Memory stage — data memory interface, store masking, load alignment, MEM/WB register
// kacassidy@hmc.edu 2025

module memory_stage (
    input  logic        clk, reset,
    // From EX/MEM register
    input  logic [31:0] aluresultm,   // memory address or result to write back
    input  logic [31:0] writedatam,   // raw rs2 value for stores
    input  logic [4:0]  rdm,
    input  logic        regwritem,
    input  logic        memwritem, resultsrcm, menenem,
    input  logic        csrsrcm,
    input  logic [2:0]  funct3m,
    input  logic [31:0] csrreaddatam,
    // Data memory interface
    input  logic [31:0] readdata,
    output logic [31:0] dataadr,
    output logic [31:0] writedata,
    output logic        memen,
    output logic        writeen,
    output logic [3:0]  writebyteen,

    // MEM/WB register outputs
    output logic [31:0] aluresultw,
    output logic [31:0] readdataw,
    output logic [4:0]  rdw,
    output logic        regwritew,
    output logic        resultsrcw, csrsrcw,
    output logic [31:0] csrreaddataw,

    // Forward to EX stage (ALU result available immediately)
    output logic [31:0] resultm
);
    assign dataadr = aluresultm;
    assign memen   = menenem;
    assign resultm = aluresultm; // load data not yet available; forward ALU result

    // Store byte-enable and write-data replication
    always_comb begin
        if (memwritem)
            case (funct3m[1:0])
                2'b00: begin  // SB
                    writebyteen = 4'b0001 << aluresultm[1:0];
                    writedata   = {4{writedatam[7:0]}};
                end
                2'b01: begin  // SH
                    writebyteen = aluresultm[1] ? 4'b1100 : 4'b0011;
                    writedata   = {2{writedatam[15:0]}};
                end
                default: begin  // SW
                    writebyteen = 4'b1111;
                    writedata   = writedatam;
                end
            endcase
        else begin
            writebyteen = 4'b0000;
            writedata   = writedatam;
        end
    end
    assign writeen = |writebyteen;

    // Load data alignment
    logic [7:0]  byteval;
    logic [15:0] halfval;
    logic [31:0] selecteddata;

    assign byteval = 8'(readdata  >> (aluresultm[1:0] * 8));
    assign halfval = 16'(readdata >> (aluresultm[1]   * 16));

    always_comb
        case (funct3m)
            3'b000: selecteddata = {{24{byteval[7]}},  byteval};   // LB
            3'b001: selecteddata = {{16{halfval[15]}}, halfval};   // LH
            3'b100: selecteddata = {24'b0, byteval};               // LBU
            3'b101: selecteddata = {16'b0, halfval};               // LHU
            default: selecteddata = readdata;                      // LW
        endcase

    // MEM/WB pipeline register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            aluresultw   <= 32'b0;  readdataw    <= 32'b0;  rdw   <= 5'b0;
            regwritew    <= 1'b0;   resultsrcw   <= 1'b0;   csrsrcw <= 1'b0;
            csrreaddataw <= 32'b0;
        end else begin
            aluresultw   <= aluresultm;
            readdataw    <= selecteddata;
            rdw          <= rdm;
            regwritew    <= regwritem;
            resultsrcw   <= resultsrcm;
            csrsrcw      <= csrsrcm;
            csrreaddataw <= csrreaddatam;
        end
    end
endmodule
