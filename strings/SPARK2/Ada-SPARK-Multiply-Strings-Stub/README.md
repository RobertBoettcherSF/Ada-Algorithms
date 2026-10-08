# Ada-SPARK-Multiply-Strings-Stub

Multiply two non-negative integers given as decimal digit strings (LeetCode 43), each of length $1..1000$ (`Max_Len`), with any `Positive` index range.

Schoolbook multiplication: digit products are summed per position (each sum $\le 81 \cdot L_1$), one carry pass from the right writes the digits, and leading zeros are stripped. Proved (Silver, `--level=2`): no run-time errors, termination, and the postcondition that the result has $1..L_1 + L_2$ characters, all digits, with no leading zero (unless it is `"0"`). The value itself is checked by the tests (2000 random pairs against `Long_Long_Integer`, and $(10^{30}-1)^2$).

Earlier this folder multiplied two `Natural` values up to 9 999.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
