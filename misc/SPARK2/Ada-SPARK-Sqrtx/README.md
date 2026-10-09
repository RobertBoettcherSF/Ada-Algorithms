# Ada-SPARK-Sqrtx

Integer square root, in SPARK. `Integer_Square_Root (Value)` returns, for `Value` in 0 .. 10,000, the largest `R` in 0 .. 100 with `R * R <= Value`. It also returns the number of candidate roots it squared (`Probes`).

It is a half-open binary search over the candidates 0 .. 101. The loop keeps `Lo * Lo <= Value < Hi * Hi` and stops when `Hi = Lo + 1`.

The postcondition `R * R <= Value < (R + 1) * (R + 1)` is proved.

Cost: O(log 101). `Probe_Count` is 0 .. 7 = ceil (log2 101), so the bound on candidates squared is proved: a ghost table bounds `Hi - Lo` by the ceiling of 101 halved once per probe. `tests.adb` and the own checks also assert at most floor (log2 101) + 2.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (17 checks).

The first version scanned down from 100 and squared each candidate (101 for `Value` 0), with no contract. Commit 507140da added a counter and a test asserting the log bound. That test fails on the old scan.
