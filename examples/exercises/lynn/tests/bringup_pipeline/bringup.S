// Pipeline Test Entry Point
// Christian LamAlvarez
// clamalvarez@hmc.edu
// 4/1/2026

.extern fail
.extern pass

// Category 1: Hazard-safe (NOP-padded)
.extern nop_alu_test
.extern nop_load_store_test
.extern nop_branch_test
.extern nop_mul_test

// Category 2: Hazard-specific
.extern raw_ex_ex_test
.extern raw_mem_ex_test
.extern load_use_test
.extern branch_flush_test
.extern waw_war_test

    .section .text.init
    .globl main
    .type  main, @function

    // Return labels must be global so tests can jump back here
    .globl return_nop_alu_test
    .globl return_nop_load_store_test
    .globl return_nop_branch_test
    .globl return_nop_mul_test

    .globl return_raw_ex_ex_test
    .globl return_raw_mem_ex_test
    .globl return_load_use_test
    .globl return_branch_flush_test
    .globl return_waw_war_test

main:
    j nop_alu_test

return_nop_alu_test:
    j nop_load_store_test

return_nop_load_store_test:
    j nop_branch_test

return_nop_branch_test:
    j nop_mul_test

return_nop_mul_test:
    j raw_ex_ex_test

return_raw_ex_ex_test:
    j raw_mem_ex_test

return_raw_mem_ex_test:
    j load_use_test

return_load_use_test:
    j branch_flush_test

return_branch_flush_test:
    j waw_war_test

return_waw_war_test:
    j pass
