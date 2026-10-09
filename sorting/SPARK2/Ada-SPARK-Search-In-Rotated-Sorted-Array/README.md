# Ada-SPARK-Search-In-Rotated-Sorted-Array

Search in a rotated sorted array, in SPARK. `Data` holds 32 distinct values in 0 .. 100: a strictly increasing array turned left by some amount. So it rises, drops once, and rises again to below its first element. That shape is the subtype predicate of `Rotated_Array`: there is a turn `P` such that the array rises strictly everywhere except into `P`, and if `P > 1` the last element is below the first.

`Contains (Data, Target)` says whether `Target` occurs, and returns the number of comparisons with elements (`Probes`). It works in three steps:
1. Halve to find the turn (the smallest element), comparing `Data (Mid)` with `Data (Hi)`, as in Find-Minimum-In-Rotated-Sorted-Array.
2. Compare `Target` with `Data (1)` to pick the sorted part that can hold it. Every value before the turn is >= `Data (1)`, and every value from the turn on is below it.
3. Run a lower-bound halving search in that part, then compare the element found.

The postcondition `Found = (for some I => Data (I) = Target)` is proved. When `Target` is absent:
- `Lemma_Absent` rules it out inside the part searched (from the two neighbours of the lower bound);
- `Lemma_Other_Part` rules it out in the other part.

Cost: O(log N). Each step has its own bounded counter: at most 5 comparisons to find the turn, 1 to pick the part, 6 to halve it, and 1 for the last comparison. So `Probe_Count` 0 .. 13 is proved. `tests.adb` and the own checks assert at most 2 * (floor (log2 N) + 2) = 14.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (80 checks), on `proof.gpr` (the package only).

`make test` runs `tests.adb` and the folder's own checks: 687,570 checks against a linear scan (see `tests/SOURCES.txt`). The measured worst case is 12 comparisons: the pick comparison happens only when the array is turned, and then each part is at most 31 long.

The first version was a linear membership scan with no contract and no rotation requirement. Its test array (4 5 6 7 0 1 2, then 100 x 25) was not a rotated sorted array. The first commit of the 2026-10-09 rewrite added a comparison counter and valid rotated test arrays. Its test, which asserts the log bound, fails on the old scan (32 comparisons).
