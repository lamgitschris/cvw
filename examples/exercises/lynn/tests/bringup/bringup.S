// C Runtime entry point
// James Kaden Cassidy
// kacassidy@hmc.edu
// 1/21/2026
// Edited by:
// Christian LamAlvarez
// clamalvarez@hmc.edu
// 2/11/2026

.extern fail
.extern pass

// Existing tests
.extern add_test
.extern or_test
.extern and_test
.extern sub_test
.extern beq_test
.extern slt_test

// Shift/compare tests
.extern sll_test
.extern slli_test
.extern srl_test
.extern srli_test
.extern sra_test
.extern srai_test
.extern sltu_test
.extern sltiu_test

// Load/store tests
.extern lb_test
.extern lbu_test
.extern lh_test
.extern lhu_test
.extern sb_test
.extern sh_test

// Branch/jump tests
.extern bne_test
.extern blt_test
.extern bltu_test
.extern bge_test
.extern bgeu_test
.extern jalr_test

// U-type tests
.extern lui_test
.extern auipc_test

    .section .text.init
    .globl main
    .type  main, @function

    // Return labels must be global so tests can jump back here
    .globl return_add_test
    .globl return_or_test
    .globl return_and_test
    .globl return_sub_test

    .globl return_sll_test
    .globl return_slli_test
    .globl return_srl_test
    .globl return_srli_test
    .globl return_sra_test
    .globl return_srai_test
    .globl return_sltu_test
    .globl return_sltiu_test

    .globl return_lb_test
    .globl return_lbu_test
    .globl return_lh_test
    .globl return_lhu_test
    .globl return_sb_test
    .globl return_sh_test

    .globl return_bne_test
    .globl return_blt_test
    .globl return_bltu_test
    .globl return_bge_test
    .globl return_bgeu_test
    .globl return_jalr_test

    .globl return_lui_test
    .globl return_auipc_test

main:
    j add_test

return_add_test:
    j or_test

return_or_test:
    j and_test

return_and_test:
    j sub_test

return_sub_test:
    j sll_test

return_sll_test:
    j slli_test

return_slli_test:
    j srl_test

return_srl_test:
    j srli_test

return_srli_test:
    j sra_test

return_sra_test:
    j srai_test

return_srai_test:
    j sltu_test

return_sltu_test:
    j sltiu_test

return_sltiu_test:
    j lb_test

return_lb_test:
    j lbu_test

return_lbu_test:
    j lh_test

return_lh_test:
    j lhu_test

return_lhu_test:
    j sb_test

return_sb_test:
    j sh_test

return_sh_test:
    j bne_test

return_bne_test:
    j blt_test

return_blt_test:
    j bltu_test

return_bltu_test:
    j bge_test

return_bge_test:
    j bgeu_test

return_bgeu_test:
    j jalr_test

return_jalr_test:
    j lui_test

return_lui_test:
    j auipc_test

return_auipc_test:
    j pass
