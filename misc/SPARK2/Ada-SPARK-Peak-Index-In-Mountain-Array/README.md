# Ada-SPARK-Peak-Index-In-Mountain-Array

Peak index in a mountain array, in SPARK. `Input` holds 32 values in -1000 .. 1000. The values rise strictly up to one peak and then fall strictly, so the peak is at 2 .. 31. That shape is the subtype predicate of `Mountain_Array`. It is stated without an existential, as four checks:
- the array rises at the start;
- it falls at the end;
- no two neighbours are equal;
- no element is below both of its neighbours (no valley).

`Peak_Index (Input)` returns the peak and the number of neighbour comparisons it made (`Probes`).

It is a binary search on the slope. It compares `Input (Mid)` with `Input (Mid + 1)`: if the array still rises there, the peak is to the right; otherwise the peak is at `Mid` or to its left.

The postcondition is proved: the array rises strictly before the returned position and falls strictly from it on. The loop keeps two facts:
- the array rises into `Lo`;
- it falls out of `Hi`.

`Lemma_Rise` and `Lemma_Fall` extend these to the whole array by induction over the no-valley and distinct-neighbour parts of the predicate.

Cost: O(log N). `Probe_Count` is 0 .. 5 = ceil (log2 30), so the bound on comparisons is proved: a ghost table bounds `Hi - Lo` by 31 / 2 ** probes. `tests.adb` and the own checks also assert at most floor (log2 N) + 2 comparisons.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (59 checks).

`make test` runs `tests.adb` and the folder's own checks: 84,592 checks against a linear arg-max and an existential mountain test (see `tests/SOURCES.txt`).

The first version (Length 8, although this README said n <= 32) was a linear arg-max over the whole array, with no contract and no mountain requirement. Commit b1033a8e added a comparison counter to it and a test asserting the log bound. That test fails on the old scan (31 comparisons for N = 32).
