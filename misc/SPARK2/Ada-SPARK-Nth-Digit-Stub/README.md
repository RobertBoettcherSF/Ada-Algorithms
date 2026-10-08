# Ada-SPARK-Nth-Digit-Stub

Digit at zero-based position $p$ of the infinite string `123456789101112...` (LeetCode 400), for every `Natural` $p$.

Numbers with $w$ digits fill $9 \cdot 10^{w-1} \cdot w$ positions. A table of running totals $C_w = \sum_{k \le w} 9 \cdot 10^{k-1} k$ gives the width $w$ for $n = p + 1$; the number is $10^{w-1} + \lfloor (n - C_{w-1} - 1) / w \rfloor$ and the digit sits at offset $(n - C_{w-1} - 1) \bmod w$. Proved (Silver, `--level=2`) free of run-time errors and terminating, with the functional postcondition $p \le 8 \Rightarrow$ result $= p + 1$. The tests compare the first ~20 000 positions with the string built directly, plus $n = 10^9 \to 1$ and $n = 2^{31} \to 5$.

Earlier this folder returned digits of `1234567890` for $p \in 0..9$ only (and gave 0 at $p = 9$, where the sequence has the 1 of 10).

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
