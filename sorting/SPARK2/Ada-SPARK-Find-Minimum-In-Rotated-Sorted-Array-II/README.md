# Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array-II

Find the minimum in a rotated sorted array with duplicates, in SPARK. `Values` holds 8 values in -1000 .. 1000: a non-decreasing array (duplicates allowed) turned left by some amount. That shape is the subtype predicate of `Rotated_Array`: there is a turn `P` such that the array never falls except into `P`, and if `P > 1` the last element is at most the first.

`Find_Minimum (Values)` returns the position of a smallest element and the number of comparisons (`Probes`); `Minimum` returns the value. It halves the range towards the turn, comparing `Values (Mid)` with `Values (Hi)`:
- larger: the turn is right of `Mid`;
- smaller: the turn is at `Mid` or to its left;
- equal: the comparison cannot tell the sides apart. Then, if the array falls into `Hi`, `Hi` is the turn; otherwise the turn is below `Hi`, and the range shrinks by one.

The postcondition is proved: no element is smaller than the one returned. The loop keeps the ghost turn (`Pivot_Of`) in `Lo .. Hi`, using:
- `Lemma_Step`: what one comparison says about the turn;
- `Lemma_Minimum`: the element at the turn is a smallest one.

Cost: with duplicates the worst case is O(N). For an array that is all equal but one, no comparison-based search can do better than looking at most elements. `Probe_Count` 0 .. N - 1 is proved through the invariant `Probes + (Hi - Lo) <= N - 1`. With distinct values the equal case never happens and the search is O(log N): `tests.adb` and the own checks assert at most floor (log2 N) + 2 comparisons there. On all-equal-but-one arrays (the 0 at every position) they check the answer only.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (53 checks).

The first version (8 values, although this README said n <= 32) was a linear minimum scan with no contract and no rotation requirement. The first commit of the 2026-10-09 rewrite added a comparison counter and a test asserting the log bound for distinct values. That test fails on the old scan (8 comparisons).
