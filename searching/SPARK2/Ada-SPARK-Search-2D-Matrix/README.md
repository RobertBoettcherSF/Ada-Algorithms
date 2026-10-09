# Ada-SPARK-Search-2D-Matrix

Search a sorted matrix, in SPARK. `Input` is 8 x 8 with values in 0 .. 99. Read row by row (row-major order), its 64 cells never decrease: each row is non-decreasing and each row starts no lower than the previous row ends. That is the subtype predicate of `Sorted_Matrix`, stated over `Cell (M, K)`, the K-th cell in row-major order (`Row_Of (K)`, `Column_Of (K)`).

`Contains (Input, Target)` returns whether some cell equals `Target`, and the number of comparisons with cells it made (`Probes`).

It treats the 64 cells as one sorted array and runs a lower-bound binary search on it: find the first cell `L` that is >= `Target`, then compare that one cell with `Target`.

The postcondition is proved: `Found` is true exactly when some cell `Cell (Input, K)` equals `Target`. `Position_Of (R, C)` has a proved postcondition that it is the cell index of `Input (R, C)`, so "some cell" is the same as "some entry". (The postcondition is stated over the flat cell index on purpose: the nested `for some R => for some C` form times out in cvc5.) When nothing is found, `Lemma_Absent` uses `Lemma_Chain` (row-major order is transitive) to show every cell before `L` is < `Target` and every cell from `L` on is > `Target`.

Cost: O(log N). `Probe_Count` is 0 .. 8: at most 7 halvings of the 65 insertion points plus 1 final comparison. A ghost table bounds `H - L` by 64 / 2 ** halvings, so the bound is proved. `tests.adb` asserts at most floor (log2 64) + 2 = 8 comparisons.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (48 checks), on `proof.gpr` (the package only).

`make test` runs `tests.adb` and the folder's own checks: 43,676 checks against a 2D scan of every entry and a row-by-row sortedness test (see `tests/SOURCES.txt`).

The first version was a 3 x 3 cell-by-cell scan with no contract and no sortedness requirement (this README called it "bounded row-major search"). The failing test that came first grew it to 8 x 8, added a comparison counter and asserted the log bound. That test fails on the old scan, which makes up to 64 comparisons.
