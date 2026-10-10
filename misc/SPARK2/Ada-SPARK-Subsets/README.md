# Ada-SPARK-Subsets

All subsets of a list by binary counting, in SPARK. A `Selection` is an array of `Boolean` that says for each item whether it is in the subset.

- `Next_Subset (S, Found)` counts up by one, with item 1 as the lowest bit. Stepping from the empty selection visits all 2 ** N subsets once. From all-True it wraps around to the empty selection, with `Found` set to False.
- `Subset (Items, S)` returns the selected items in their order, with index range 1 .. count.
- `Count (N)` is 2 ** N.

**Range widened:** the first version was only a case table of 2 ** N for N <= 12, with no subsets at all. `Count` now goes up to N = 30, because 2 ** 30 = 1_073_741_824 fits `Natural` and 2 ** 31 does not. The selections that `Next_Subset` steps through (`Small_Selection`) have the same limit of 30 items, so that their rank is a `Natural`; more could never be counted through anyway. `Subset` takes lists of any length. Its contract checks under `-gnata` cost O(N ** 3) per call, so the tests use lists of up to 40 items.

The proved contracts (205 checks), at any origin (`'First` is not pinned to 1; a selection's lowest bit is `S (S'First)`, and `Subset` pairs `S` and `Items` by position, so they may start at different indexes):
- `Next_Subset` raises the ghost rank (the number the selection stands for) by exactly 1. It sets `Found` to False exactly when the rank was 2 ** N - 1, and the selection is then all False.
- `Subset` returns exactly as many items as are selected, and the K-th selected item sits at position "number of selected items up to K" counted from the result's first index (the result is built from 1; the Post does not promise that).
- `Count = Pow2 (N)`, against a ghost table whose doubling is proved.

## Checks

```text
make test
make prove
```

`make prove` runs level-2 GNATprove with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
