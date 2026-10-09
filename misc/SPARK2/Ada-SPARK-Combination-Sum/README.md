# Ada-SPARK-Combination-Sum

Combination Sum, counting version, in SPARK. `Count_Limited (Value, Max_Part)` returns the number of ways to write `Value` as a sum of candidates 1 .. `Max_Part`, each usable any number of times, where order does not matter. `Count_Combinations (Value)` uses every candidate 1 .. `Value`, which gives the partition number p (Value).

The code is the coin-change DP: one count per target, and for each part C from 1 up, `W (V) := W (V) + W (V - C)` from left to right, so `W (V - C)` already includes part C and can use it again. O(Value * Max_Part) additions.

**Range widened:** the first version was a case table of p (n) for n in 0 .. 12. Targets are now 0 .. 31, and `Count_Limited` is new. The limit comes from the proved bound P (N, C) <= 2 ** (N + C): with N + C <= 62 every count fits `Long_Long_Integer` (0 .. 2 ** 62). The real values are much smaller (p (31) = 6_842, and p (n) fits `Natural` up to n = 121), but the simple recurrence gives no tighter bound.

The proved contract is `Count_Limited (Value, Max_Part) = P (Value, Max_Part)`, where the ghost `P (N, C)` is the recurrence "no part equals C, or take one part C off" and carries the bound above (37 checks).

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
