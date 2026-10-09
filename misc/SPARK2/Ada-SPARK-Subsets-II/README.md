# Ada-SPARK-Subsets-II

Distinct subsets of a list that may repeat items, in SPARK.

The list is given as its distinct values together with how many copies of each it holds. For example, 1 1 2 is the values 1, 2 with copies 2, 1. A distinct subset is then a choice of how many copies of each value to take, `Take (I)` in 0 .. `Copies (I)`, so no subset can appear twice. The `Choice` type keeps `Take (I) <= Copies (I)` in its predicate.

- `Next_Choice (C, Found)` counts through the choices like an odometer, with the first value as the lowest digit. From the last choice (everything taken) it wraps around to the empty subset and sets `Found` to False.
- `Subset (Values, C)` lists the chosen items: `Take (1)` copies of `Values (1)`, then `Take (2)` copies of `Values (2)`, and so on.
- `Count (C)` is the number of distinct subsets, the product of (`Copies (I)` + 1).

**Range widened:** the first version was a case table of 2 ** N for N <= 12 distinct values, with no subsets at all. The limit is now 30 items in all. Each value adds a factor `Copies + 1 <= 2 ** Copies`, so the count is at most 2 ** 30 = 1_073_741_824, which fits `Natural`. 31 distinct items would give 2 ** 31, which does not fit.

The proved contracts (225 checks):
- `Next_Choice` keeps `Copies`. It sets `Found` to False exactly when everything was taken, and the choice is then empty. Otherwise the new choice is strictly later in colex order: the highest position where the two choices differ went up.
- `Subset` returns `Total (Take)` items, and each position holds the value of its run (ghost `Group`).
- `Count` equals a ghost `Big_Integer` product, and the bound 2 ** 30 is proved.

That each step moves to the *next* choice is checked by the tests: brute force over all index subsets of the written-out list, and an own mixed-radix rank.

## Checks

```text
make test
make prove
```

`make prove` runs level-2 GNATprove with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
