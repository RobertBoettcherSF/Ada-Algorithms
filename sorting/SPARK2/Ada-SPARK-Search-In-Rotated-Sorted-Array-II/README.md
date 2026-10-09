# Ada-SPARK-Search-In-Rotated-Sorted-Array-II

Search in a rotated sorted array with duplicates, in SPARK. `Data` holds 32 values in 0 .. 100: a non-decreasing array (duplicates allowed) turned left by some amount. That shape is the subtype predicate of `Rotated_Array`: there is a turn `P` such that the array never falls except into `P`, and if `P > 1` the last element is at most the first.

`Contains (Data, Target)` says whether `Target` occurs, and returns the number of comparisons with elements (`Probes`). It works in three steps:
1. Find the turn as in Find-Minimum-In-Rotated-Sorted-Array-II: halve by comparing `Data (Mid)` with `Data (Hi)`. On equal ends, `Hi` is the turn if the array falls into it; otherwise the range shrinks by one.
2. Compare `Target` with `Data (1)` to pick the sorted part.
3. Run a lower-bound halving search in that part, then compare the element found.

The postcondition `Found = (for some I => Data (I) = Target)` is proved. When `Target` is absent:
- `Lemma_Absent` rules it out in the part searched;
- `Lemma_Other_Part` rules it out in the other part. This needs `Target` /= `Data (1)`, which the first lemma gives when the first part was searched.

Cost: with duplicates the worst case is O(N). On an array that is all equal but one, the turn cannot be found without looking at most elements. The proved bound is (N - 1) + 1 + 6 + 1 comparisons: the turn search keeps `Probes + (Hi - Lo) <= N - 1`. With distinct values the equal-ends step never happens and the cost is O(log N): `tests.adb` and the own checks assert at most 2 * (floor (log2 N) + 2) there. With duplicates they check the answer only, including all-equal-but-one arrays with the odd value at every position.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (87 checks), on `proof.gpr` (the package only).

`make test` runs `tests.adb` and the folder's own checks: 410,978 checks against a linear scan (see `tests/SOURCES.txt`).

The first version was a linear membership scan with no contract. Its test array (4 5 6 7 0 1 2, then 100 x 25) was not a rotated sorted array. The first commit of the 2026-10-09 rewrite added a comparison counter and valid test arrays. Its test, which asserts the log bound for distinct values, fails on the old scan (32 comparisons).
