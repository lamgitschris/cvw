// execute_stage.sv
// Execute stage — forwarding, ALU, branch resolution, EX/MEM pipeline register
// kacassidy@hmc.edu 2025
//
// Branch/jump resolved here:
//   pcsrce = 1 on taken branch or any jump
//   pctargete = PC+imm (branch/JAL) or rs1+imm (JALR)

module execute_stage (
    input  logic        clk, reset,
    // Forwarded values from MEM and WB
    input  logic [31:0] resultm, resultw,
    // From ID/EX register — data
    input  logic [31:0] rd1e, rd2e, pce, pcplus4e, immexte,
    input  logic [4:0]  rde,
    // From ID/EX register — control
    input  logic        regwritee,
    input  logic [1:0]  alusrce,
    input  logic [1:0]  alucontrole,
    input  logic        aluresultsrce,
    input  logic        memwritee, resultsrce,
    input  logic        branche, jumpe, memene,
    input  logic        luie, csrsrce,
    input  logic [2:0]  funct3e,
    input  logic        funct7b5e,
    input  logic [11:0] csradre,
    // Forwarding selects from hazard unit
    input  logic [1:0]  forwardae, forwardbe,
    // CSR read data (combinational)
    input  logic [31:0] csrreaddatae,

    // To IFU and hazard unit
    output logic        pcsrce,
    output logic [31:0] pctargete,

    // EX/MEM register outputs
    output logic [31:0] aluresultm,
    output logic [31:0] writedatam,
    output logic [4:0]  rdm,
    output logic        regwritem,
    output logic        memwritem, resultsrcm, menenem,
    output logic        csrsrcm,
    output logic [2:0]  funct3m,
    output logic [31:0] csrreaddatam
);
    // Forwarding muxes — select final register values before ALU source mux
    logic [31:0] srca_pre, srcb_pre;
    mux3 #(32) fwda (rd1e, resultw, resultm, forwardae, srca_pre);
    mux3 #(32) fwdb (rd2e, resultw, resultm, forwardbe, srcb_pre);

    // ALU source muxes
    // SrcA: register or PC (AUIPC/JAL/branches)
    // SrcB: register or immediate
    logic [31:0] srca, srcb;
    mux2 #(32) srcamux (srca_pre, pce,      alusrce[1], srca);
    mux2 #(32) srcbmux (srcb_pre, immexte,  alusrce[0], srcb);

    // ALU
    logic [31:0] aluresulte;
    alu alu_inst (
        .srca, .srcb,
        .alucontrol(alucontrole),
        .funct3(funct3e), .funct7b5(funct7b5e),
        .lui(luie),
        .aluresult(aluresulte)
    );

    // Branch comparator — uses pre-mux register values
    logic branchope;
    cmp cmp_inst (.a(srca_pre), .b(srcb_pre), .funct3(funct3e), .branchop(branchope));

    // Result mux — JAL/JALR write PC+4 as link value; others write ALU result
    logic [31:0] ieure;
    mux2 #(32) linkresultmux (aluresulte, pcplus4e, aluresultsrce, ieure);

    // Branch/jump target
    // Branches + JAL: PC + sign-extended immediate
    // JALR:           rs1 + imm = ALU result
    logic [31:0] pcbranche;
    adder      branchadd  (pce, immexte, pcbranche);
    mux2 #(32) pctargetmux (pcbranche, aluresulte,
                             jumpe & ~alusrce[1], // JALR: jump with register base (alusrce[1]=0)
                             pctargete);

    assign pcsrce = (branche & branchope) | jumpe;

    // EX/MEM pipeline register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            aluresultm   <= 32'b0;  writedatam   <= 32'b0;  rdm    <= 5'b0;
            regwritem    <= 1'b0;   memwritem    <= 1'b0;   resultsrcm <= 1'b0;
            menenem      <= 1'b0;   csrsrcm      <= 1'b0;
            funct3m      <= 3'b0;   csrreaddatam <= 32'b0;
        end else begin
            aluresultm   <= ieure;      // link value (PC+4) or ALU result
            writedatam   <= srcb_pre;   // raw rs2 for stores (not immediate-muxed)
            rdm          <= rde;
            regwritem    <= regwritee;
            memwritem    <= memwritee;
            resultsrcm   <= resultsrce;
            menenem      <= memene;
            csrsrcm      <= csrsrce;
            funct3m      <= funct3e;
            csrreaddatam <= csrreaddatae;
        end
    end
endmodule
