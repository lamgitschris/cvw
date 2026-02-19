// Christian LamAlvarez
// clamalvarez@hmc.edu
// 2/09/2026

.extern return_slli_test
.extern fail

.section .text.init
.globl slli_test
.type  slli_test, @function

slli_test:
    test1:
        addi t0, x0, 1
        slli t2, t0, 1           # 1 << 1 = 2
        addi t3, x0, 2
        beq  t2, t3, test2
        jal  x0, Fail_SLLI_1

    test2:
        addi t0, x0, 5
        slli t2, t0, 2           # 5 << 2 = 20
        addi t3, x0, 20
        beq  t2, t3, test3
        jal  x0, Fail_SLLI_2

    test3:
        addi t0, x0, 7
        slli t2, t0, 0           # shift by 0 => unchanged
        addi t3, x0, 7
        beq  t2, t3, test4
        jal  x0, Fail_SLLI_3

    test4:
        addi t0, x0, 1
        slli t2, t0, 31          # 1 << 31 = 0x80000000

        lui  t3, 0x80000         # load upper 20 bits
        addi t3, t3, 0           # lower bits = 0

        beq  t2, t3, test5
        jal  x0, Fail_SLLI_4

    test5:
        addi t0, x0, -1          # 0xFFFFFFFF
        slli t2, t0, 1           # -> 0xFFFFFFFE (-2)
        addi t3, x0, -2
        beq  t2, t3, test6
        jal  x0, Fail_SLLI_5

    test6:
        addi t0, x0, 3
        slli t2, t0, 4           # 3 << 4 = 48
        addi t3, x0, 48
        beq  t2, t3, test7
        jal  x0, Fail_SLLI_6

    test7:
        addi t0, x0, 16
        slli t2, t0, 3           # 16 << 3 = 128
        addi t3, x0, 128
        beq  t2, t3, test8
        jal  x0, Fail_SLLI_7

    test8:
        addi t0, x0, 0
        slli t2, t0, 13          # 0 stays 0
        addi t3, x0, 0
        beq  t2, t3, test9
        jal  x0, Fail_SLLI_8

    test9:
        lui  t0, 0x80000
        addi t0, t0, 0

        slli t2, t0, 1           # shift out top bit
        addi t3, x0, 0
        beq  t2, t3, test10
        jal  x0, Fail_SLLI_9

    test10:
        addi t0, x0, 15          # 0x0F
        slli t2, t0, 3           # 0x0F << 3 = 0x78 (120)
        addi t3, x0, 120
        beq  t2, t3, pass
        jal  x0, Fail_SLLI_10

    pass:
        jal  x0, return_slli_test

Fail_SLLI_1:
    addi gp, x0, 601
    jal  x0, fail

Fail_SLLI_2:
    addi gp, x0, 602
    jal  x0, fail

Fail_SLLI_3:
    addi gp, x0, 603
    jal  x0, fail

Fail_SLLI_4:
    addi gp, x0, 604
    jal  x0, fail

Fail_SLLI_5:
    addi gp, x0, 605
    jal  x0, fail

Fail_SLLI_6:
    addi gp, x0, 606
    jal  x0, fail

Fail_SLLI_7:
    addi gp, x0, 607
    jal  x0, fail

Fail_SLLI_8:
    addi gp, x0, 608
    jal  x0, fail

Fail_SLLI_9:
    addi gp, x0, 609
    jal  x0, fail

Fail_SLLI_10:
    addi gp, x0, 610
    jal  x0, fail
