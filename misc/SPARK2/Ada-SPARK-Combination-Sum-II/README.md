# Ada-SPARK-Combination-Sum-II

Combination Sum II, counting version, in SPARK. `Count_Limited (Value, Max_Part)` returns the number of ways to write `Value` as a sum of distinct candidates from 1 .. `Max_Part` (each used at most once, order does not matter). `Count_Distinct_Combinations (Value)` uses candidates 1 .. `Value`, which gives q (Value), the number of partitions into distinct parts.

The code is the 0/1 knapsack DP: one count per target, and for each part C, `W (V) := W (V) + W (V - C)` from right to left, so `W (V - C)` still counts only sets without C and C is used at most once. O(Value * Max_Part) additions.

**Range widened:** the first version was a case table of q (n) for n in 0 .. 12. Targets are now 0 .. 30, and `Count_Limited` is new. A set of parts from 1 .. C is one of 2 ** C subsets, so every count is <= 2 ** 30 and fits `Natural`.

The proved contract is `Count_Limited (Value, Max_Part) = Q (Value, Max_Part)`, where the ghost `Q (N, C)` is the recurrence "C unused, or used once" and carries the bound Q (N, C) <= 2 ** C (38 checks).

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
