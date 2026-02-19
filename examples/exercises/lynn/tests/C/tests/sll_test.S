// Christian LamAlvarez
// clamalvarez@hmc.edu
// 2/09/2026

.extern return_sll_test
.extern fail

.section .text.init
.globl sll_test
.type  sll_test, @function

sll_test:
    test1:
        addi t0, x0, 1          # rs1 = 1
        addi t1, x0, 1          # shamt = 1
        sll  t2, t0, t1         # 1 << 1 = 2
        addi t3, x0, 2
        beq  t2, t3, test2
        jal  x0, Fail_SLL_1

    test2:
        addi t0, x0, 5          # 0b0101
        addi t1, x0, 2
        sll  t2, t0, t1         # 5 << 2 = 20
        addi t3, x0, 20
        beq  t2, t3, test3
        jal  x0, Fail_SLL_2

    test3:
        addi t0, x0, 7
        addi t1, x0, 0
        sll  t2, t0, t1         # shift by 0 => unchanged
        addi t3, x0, 7
        beq  t2, t3, test4
        jal  x0, Fail_SLL_3

    test4:
        addi t0, x0, 1
        addi t1, x0, 31
        sll  t2, t0, t1         # 1 << 31 = 0x80000000 (sign bit set)

        lui  t3, 0x80000      # upper 20 bits
        addi t3, t3, 0        # lower bits

        beq  t2, t3, test5
        jal  x0, Fail_SLL_4

    test5:
        addi t0, x0, -1         # 0xFFFFFFFF
        addi t1, x0, 1
        sll  t2, t0, t1         # 0xFFFFFFFF << 1 = 0xFFFFFFFE (= -2)
        addi t3, x0, -2
        beq  t2, t3, test6
        jal  x0, Fail_SLL_5

    test6:
        addi t0, x0, 3
        addi t1, x0, 4
        sll  t2, t0, t1         # 3 << 4 = 48
        addi t3, x0, 48
        beq  t2, t3, test7
        jal  x0, Fail_SLL_6

    test7:
        addi t0, x0, 16         # 0x10
        addi t1, x0, 3
        sll  t2, t0, t1         # 0x10 << 3 = 0x80 (= 128)
        addi t3, x0, 128
        beq  t2, t3, test8
        jal  x0, Fail_SLL_7

    test8:
        addi t0, x0, 0
        addi t1, x0, 13
        sll  t2, t0, t1         # 0 << anything = 0
        addi t3, x0, 0
        beq  t2, t3, test9
        jal  x0, Fail_SLL_8

    test9:
        addi t0, x0, 1
        addi t1, x0, 32         # RV32 uses low 5 bits: 32 -> 0
        sll  t2, t0, t1         # behaves like shift by 0 => 1
        addi t3, x0, 1
        beq  t2, t3, test10
        jal  x0, Fail_SLL_9

    test10:
        addi t0, x0, 7
        addi t1, x0, 33         # low 5 bits: 33 -> 1
        sll  t2, t0, t1         # 7 << 1 = 14
        addi t3, x0, 14
        beq  t2, t3, pass
        jal  x0, Fail_SLL_10

    pass:
        jal  x0, return_sll_test

Fail_SLL_1:
    addi gp, x0, 501
    jal  x0, fail

Fail_SLL_2:
    addi gp, x0, 502
    jal  x0, fail

Fail_SLL_3:
    addi gp, x0, 503
    jal  x0, fail

Fail_SLL_4:
    addi gp, x0, 504
    jal  x0, fail

Fail_SLL_5:
    addi gp, x0, 505
    jal  x0, fail

Fail_SLL_6:
    addi gp, x0, 506
    jal  x0, fail

Fail_SLL_7:
    addi gp, x0, 507
    jal  x0, fail

Fail_SLL_8:
    addi gp, x0, 508
    jal  x0, fail

Fail_SLL_9:
    addi gp, x0, 509
    jal  x0, fail

Fail_SLL_10:
    addi gp, x0, 510
    jal  x0, fail
