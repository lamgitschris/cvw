// decode_stage.sv
// Decode stage — register file reads, control decode, and ID/EX pipeline register
// kacassidy@hmc.edu 2025

module decode_stage (
    input  logic        clk, reset,
    input  logic        flushe,
    // From IF/ID register
    input  logic [31:0] instrd, pcd, pcplus4d,
    // Writeback port (from WB stage)
    input  logic        regwritew,
    input  logic [4:0]  rdw,
    input  logic [31:0] resultw,

    // ID/EX register outputs — data
    output logic [31:0] rd1e, rd2e,
    output logic [31:0] pce, pcplus4e, immexte,
    output logic [4:0]  rs1e, rs2e, rde,
    // ID/EX register outputs — control
    output logic        regwritee,
    output logic [1:0]  alusrce,
    output logic [1:0]  alucontrole,
    output logic        aluresultsrce,
    output logic        memwritee, resultsrce,
    output logic        branche, jumpe, memene,
    output logic        luie, csrsrce,
    // Instruction fields needed in EX
    output logic [2:0]  funct3e,
    output logic        funct7b5e,
    output logic [11:0] csradre
);
    // Register file reads
    logic [31:0] rd1d, rd2d;
    regfile rf (
        .clk,
        .we3(regwritew), .a3(rdw),       .wd3(resultw),
        .a1(instrd[19:15]),              .rd1(rd1d),
        .a2(instrd[24:20]),              .rd2(rd2d)
    );

    // Immediate generator
    logic [31:0] immextd;
    logic [2:0]  immsrcd;
    extend ext (.instr(instrd[31:7]), .immsrc(immsrcd), .immext(immextd));

    // Control decoder
    logic        regwrited, aluresultsrcd;
    logic [1:0]  alusrcd, alucontrold;
    logic        memwrited, resultsrcd, branchd, jumpd, menend, luid;

    controller ctrl (
        .op      (instrd[6:0]),
        .funct3  (instrd[14:12]),
        .funct7b5(instrd[30]),
        .regwrite(regwrited),   .immsrc(immsrcd),
        .alusrc  (alusrcd),     .alucontrol(alucontrold),
        .aluresultsrc(aluresultsrcd),
        .memwrite(memwrited),   .resultsrc(resultsrcd),
        .branch  (branchd),     .jump(jumpd),
        .memen   (menend),      .lui(luid)
    );

    // CSRSrc: CSRRS/CSRRCI — op=1110011, funct3=010
    logic csrsrcd;
    assign csrsrcd = (instrd[6:0] == 7'b1110011) & (instrd[14:12] == 3'b010);

    // ID/EX pipeline register — flush inserts bubble
    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushe) begin
            rd1e <= 32'b0;  rd2e <= 32'b0;
            pce  <= 32'b0;  pcplus4e <= 32'b0;  immexte <= 32'b0;
            rs1e <= 5'b0;   rs2e <= 5'b0;        rde  <= 5'b0;
            regwritee     <= 1'b0;  alusrce      <= 2'b0;
            alucontrole   <= 2'b0;  aluresultsrce <= 1'b0;
            memwritee     <= 1'b0;  resultsrce   <= 1'b0;
            branche       <= 1'b0;  jumpe        <= 1'b0;
            memene        <= 1'b0;  luie         <= 1'b0;
            csrsrce       <= 1'b0;
            funct3e       <= 3'b0;  funct7b5e    <= 1'b0;
            csradre       <= 12'b0;
        end else begin
            rd1e <= rd1d;   rd2e <= rd2d;
            pce  <= pcd;    pcplus4e <= pcplus4d;  immexte <= immextd;
            rs1e <= instrd[19:15];
            rs2e <= instrd[24:20];
            rde  <= instrd[11:7];
            regwritee     <= regwrited;
            alusrce       <= alusrcd;
            alucontrole   <= alucontrold;
            aluresultsrce <= aluresultsrcd;
            memwritee     <= memwrited;
            resultsrce    <= resultsrcd;
            branche       <= branchd;
            jumpe         <= jumpd;
            memene        <= menend;
            luie          <= luid;
            csrsrce       <= csrsrcd;
            funct3e       <= instrd[14:12];
            funct7b5e     <= instrd[30];
            csradre       <= instrd[31:20];
        end
    end
endmodule
