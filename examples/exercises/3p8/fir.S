// fir.s
// clamalvarez@hmc.edu 3 February 2026
// n M-tap Finite Impulse Response (FIR) filter
// computes an N-M+1-element output sequence {Y[0], Y[1], …, Y[N-M+1]}
// as a weighted sum based on an N-element input sequence {X[0], X[1], …, X[N-1]}
// and M filter coefficients {c[0], c[1], …, c[M-1]}

// void fir(int x[], int c[], int y[], int n, int m) {
//   int i, j;
//   for (j=0; j<n-m+1; j++) {
//     y[j] = 0;
//     for (i=0; i<m; i++)
//       y[j] = add_q31(y[j], mul_q31(c[i], x[j-i+(m-1)]));
//   }
// }

// Argument Registers
// a0 = x
// a1 = c
// a2 = y
// a3 = n
// a4 = m

// Saved Registers
// s0 = x base
// s1 = c base
// s2 = y base
// s3 = out_len = (n - m + 1)
// s4 = j
// s6 = x_start = j + (m - 1)

.global fir
fir:
    mv      s0, a0               # s0 = x
    mv      s1, a1               # s1 = c
    mv      s2, a2               # s2 = y

    blt     a3, a4, done         # if (n < m) return

    sub     t0, a3, a4           # t0 = n - m
    addi    t0, t0, 1            # t0 = n - m + 1
    slli    t0, t0, 32           # shift to clear sign
    srli    s3, t0, 32           # s3 = out_len

    blez    a4, zero             # if (m <= 0) zero output

    li      s4, 0                # j = 0
    addiw   s6, a4, -1           # x_start = m - 1

for_j:
    bge     s4, s3, done         # exit loop if j >= out_len

    li      t4, 0                # acc = 0
    addiw   t1, s4, -1           # t1 = j - 1

    slli    t2, s4, 2            # t2 = 4*j
    add     t2, t2, s2           # t2 = &y[j]
    sw      zero, 0(t2)          # y[j] = 0

    mv      t5, s1               # t5 = &c[0]
    mv      t6, s6               # t6 = x_index = j + (m - 1)

for_i:
    beq     t6, t1, end_i        # exit inner loop if x_index == j - 1

    lw      t3, 0(t5)            # t3 = c[i]

    slli    t0, t6, 2            # t0 = 4*x_index
    add     t0, t0, s0           # t0 = &x[x_index]
    lw      t0, 0(t0)            # t0 = x[x_index]

    addiw   t6, t6, -1           # x_index--

    mul     t0, t0, t3           # product = x * c
    srli    t0, t0, 31           # product >> 31
    add     t4, t4, t0           # acc += product
    sw      t4, 0(t2)            # y[j] = acc

    addi    t5, t5, 4            # i++
    j       for_i                # repeat inner loop

end_i:
    addi    s4, s4, 1            # j++
    addiw   s6, s6, 1            # update x_start
    j       for_j                # repeat outer loop

zero:
    slli    t0, s3, 2            # byte_count = out_len * 4
    mv      a0, s2               # destination = y
    li      a1, 0                # fill value = 0
    mv      a2, t0               # size = byte_count
    call    memset               # memset(y, 0, size)

done:
    ret                          # return
