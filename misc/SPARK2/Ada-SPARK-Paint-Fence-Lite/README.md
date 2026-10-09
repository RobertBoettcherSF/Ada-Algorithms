# Ada-SPARK-Paint-Fence-Lite

Paint fence in SPARK: N posts in a row, K colours, and no three adjacent posts of the same colour. `Count (N, K, M)` is the number of colourings mod M. The loop keeps two counts mod M: colourings whose last two posts have the same colour, and colourings whose last two differ. A new post either repeats the last colour, which is allowed only after a "different" ending, or takes one of the K - 1 other colours.

**Range widened:** the first version was a case table of two-colour answers for N <= 16. Now K is any `Positive`, M is any `Positive`, and N goes up to 1_000; the old answers are still tested, exactly, with modulus 2 ** 31 - 1. Every value is a residue below 2 ** 31 and every product of two residues is below 2 ** 62, so the arithmetic itself puts no limit on N or K. The limit on N comes from run time: under `-gnata` the loop invariant evaluates the ghost recurrence, so a call costs O (N ** 2), about 0.06 s at N = 1_000.

The proved contract is `Count = T (N, K, M)` (142 checks). The ghost `T` is the two-term recurrence T (1) = K, T (2) = K * K, T (N) = (K - 1) (T (N - 1) + T (N - 2)), all mod M. That is a different formulation from the code's same/different pair, so the proof needs modular distributivity. That lemma, and the uniqueness of the remainder it rests on, are proved with `Ada.Numerics.Big_Numbers.Big_Integers` in ghost code.

## Checks

```text
make test
make prove
```

`make prove` runs level-2 GNATprove with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
