# Ada-SPARK-Sqrt-X

Integer square root in SPARK, by Newton's (Heron's) iteration. `Sqrt (N)` returns the floor of the square root of any `Natural` N and the number of Newton steps. `Floor_Sqrt (N)` returns only the root.

The iteration starts from X = 46_340, the floor of the square root of Natural'Last, and replaces X by (X + N / X) / 2 while that lowers X. It stops at X = 0 (only for N = 0).

**Range widened:** the first version was a case table of the answers for N in 0 .. 100 (Root 0 .. 10). The input is now all of `Natural` (0 .. 2 ** 31 - 1), and `Root` is 0 .. 46_340 (46_340 ** 2 = 2_147_395_600 <= Natural'Last < 46_341 ** 2).

The proved contract is `R * R <= N < (R + 1) ** 2`, with the squares taken in `Long_Long_Integer` (81 checks). `Lemma_Step` shows, through AM-GM, that a step keeps N < (X + 1) ** 2 and lowers X while X * X > N. For the cost, only `Steps + Root <= 46_340` is proved (X falls on every step but the last). The real worst case is 16 steps, at N = 0. A one-off exhaustive run over all of `Natural` confirmed this (see `tests/SOURCES.txt`). The tests check exact step counts on fixed inputs, and at most 16 steps on every input they try.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
