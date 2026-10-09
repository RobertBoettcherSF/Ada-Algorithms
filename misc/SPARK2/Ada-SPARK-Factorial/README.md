# Ada-SPARK Factorial

N! in SPARK. `Compute (N)` multiplies 1 .. N in a loop over `Long_Long_Integer`.

**Range widened:** the first version was a case table for N in 0 .. 12 (the `Natural` limit, since 13! = 6_227_020_800). N now goes to 20, the arithmetic limit of `Long_Long_Integer`: 20! = 2_432_902_008_176_640_000 fits, and 21! = 51_090_942_171_709_440_000 does not.

The proved contract is `Compute (N) = Fact (N)`, where the ghost `Fact` is the recursive definition 0! = 1, N! = N * (N - 1)! (14 checks). To show that no product overflows, the proof needs the size of each value. A ghost table of N! for N <= 20 gives them, and the proof checks every entry against the recurrence. The code never reads the table, and the tests regenerate it.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
