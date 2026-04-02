// riscvpipe.sv
// Top-level 5-stage pipelined RISC-V processor
// kacassidy@hmc.edu 2025
//
// Stages: Fetch (F) → Decode (D) → Execute (E) → Memory (M) → Writeback (W)
// Hazard handling: full forwarding, load-use stall, branch/jump flush (resolved in EX)

`include "parameters.svh"

module riscvpipe (
    input  logic        clk, reset,
    output logic [31:0] PC,          // instruction memory address
    input  logic [31:0] Instr,       // instruction memory read data
    output logic [31:0] IEUAdr,      // data memory address
    input  logic [31:0] ReadData,    // data memory read data
    output logic [31:0] WriteData,   // data memory write data
    output logic        MemEn,
    output logic        WriteEn,
    output logic [3:0]  WriteByteEn
);
    // IF/ID wires
    logic [31:0] instrd, pcd, pcplus4d;

    // ID/EX wires — data
    logic [31:0] rd1e, rd2e, pce, pcplus4e, immexte;
    logic [4:0]  rs1e, rs2e, rde;
    // ID/EX wires — control
    logic        regwritee, aluresultsrce, memwritee, resultsrce;
    logic        branche, jumpe, memene, luie, csrsrce;
    logic [1:0]  alusrce, alucontrole;
    logic [2:0]  funct3e;
    logic        funct7b5e;
    logic [11:0] csradre;

    // EX/MEM wires
    logic [31:0] aluresultm_w, writedatam;
    logic [4:0]  rdm;
    logic        regwritem, memwritem, resultsrcm, menenem, csrsrcm;
    logic [2:0]  funct3m;
    logic [31:0] csrreaddatam, resultm;

    // MEM/WB wires
    logic [31:0] aluresultw, readdataw, csrreaddataw;
    logic [4:0]  rdw;
    logic        regwritew, resultsrcw, csrsrcw;
    logic [31:0] resultw;

    // Hazard/control wires
    logic        stallf, stalld, flushd, flushe, pcsrce;
    logic [31:0] pctargete;
    logic [1:0]  forwardae, forwardbe;

    // CSR — reads cycle counter combinationally in EX stage
    logic [31:0] csrreaddatae;
    csrfile csr (
        .clk, .reset,
        .csradr(csradre),
        .csrreaddata(csrreaddatae)
    );

    // Hazard unit
    hazard hu (
        .rs1e, .rs2e,
        .rdm,  .rdw,
        .regwritem, .regwritew,
        .resultsrce,
        .rs1d(instrd[19:15]), .rs2d(instrd[24:20]),
        .rde,
        .pcsrce,
        .forwardae, .forwardbe,
        .stallf, .stalld,
        .flushd, .flushe
    );

    // Fetch stage
    ifu fetch (
        .clk, .reset,
        .stallf, .stalld, .flushd,
        .pcsrce, .pctargete,
        .instrf(Instr),
        .pc(PC),
        .instrd, .pcd, .pcplus4d
    );

    // Decode stage
    decode_stage id_stage (
        .clk, .reset,
        .flushe,
        .instrd, .pcd, .pcplus4d,
        .regwritew, .rdw, .resultw,
        .rd1e, .rd2e, .pce, .pcplus4e, .immexte,
        .rs1e, .rs2e, .rde,
        .regwritee, .alusrce, .alucontrole,
        .aluresultsrce, .memwritee, .resultsrce,
        .branche, .jumpe, .memene,
        .luie, .csrsrce,
        .funct3e, .funct7b5e, .csradre
    );

    // Execute stage
    execute_stage ex_stage (
        .clk, .reset,
        .resultm, .resultw,
        .rd1e, .rd2e, .pce, .pcplus4e, .immexte,
        .rde,
        .regwritee, .alusrce, .alucontrole,
        .aluresultsrce, .memwritee, .resultsrce,
        .branche, .jumpe, .memene,
        .luie, .csrsrce,
        .funct3e, .funct7b5e, .csradre,
        .forwardae, .forwardbe,
        .csrreaddatae,
        .pcsrce, .pctargete,
        .aluresultm(aluresultm_w),
        .writedatam, .rdm,
        .regwritem, .memwritem, .resultsrcm, .menenem,
        .csrsrcm, .funct3m, .csrreaddatam
    );

    // Memory stage
    memory_stage mem_stage (
        .clk, .reset,
        .aluresultm(aluresultm_w),
        .writedatam, .rdm,
        .regwritem, .memwritem, .resultsrcm, .menenem,
        .csrsrcm, .funct3m, .csrreaddatam,
        .readdata(ReadData),
        .dataadr(IEUAdr),
        .writedata(WriteData),
        .memen(MemEn), .writeen(WriteEn), .writebyteen(WriteByteEn),
        .aluresultw, .readdataw, .rdw,
        .regwritew, .resultsrcw, .csrsrcw,
        .csrreaddataw, .resultm
    );

    // Writeback stage
    writeback_stage wb_stage (
        .aluresultw, .readdataw,
        .resultsrcw, .csrsrcw, .csrreaddataw,
        .resultw
    );

endmodule
