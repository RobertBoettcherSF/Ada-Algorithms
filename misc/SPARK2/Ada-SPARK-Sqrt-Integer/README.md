# Ada-SPARK-Sqrt-Integer

Integer square root in SPARK, by the bit-by-bit (digit-by-digit) method. `Sqrt (N)` returns the floor of the square root of any `Natural` N and the number of steps taken. `Floor_Sqrt (N)` returns only the root.

The root of a 31-bit value has at most 16 bits. The method tries each bit from 2 ** 15 down to 2 ** 0, and keeps a bit when the square of the candidate is still <= N. That is exactly 16 steps (one comparison each) for every input.

**Range widened:** the first version was a case table of the answers for N in 0 .. 100 (Root 0 .. 10). The input is now all of `Natural` (0 .. 2 ** 31 - 1), and `Root` is 0 .. 46_340 (46_340 ** 2 = 2_147_395_600 <= Natural'Last < 46_341 ** 2).

The proved contract is `R * R <= N < (R + 1) ** 2` with the squares taken in `Long_Long_Integer`, plus `Steps = 16` (32 checks). The loop invariant is `R * R <= N < (R + 2 * Bit) ** 2` with `Bit = 2 ** I`. A ghost table of the 16 powers of two feeds the proof; the prover checks it against the halving of `Bit`.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
