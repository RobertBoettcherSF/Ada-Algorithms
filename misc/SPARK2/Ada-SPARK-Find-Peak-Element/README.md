# Ada-SPARK-Find-Peak-Element

Find a peak element, in SPARK. `Input` holds 32 values in -1000 .. 1000, and no two neighbours are equal (the subtype predicate of `Input_Array`). A peak is an element greater than each neighbour it has; the two ends have only one neighbour. Such an element always exists, and there may be several.

`Find_Peak (Input)` returns one peak and the number of neighbour comparisons it made (`Probes`).

It is a binary search on the slope. It compares `Input (Mid)` with `Input (Mid + 1)`: if the array rises there, a peak lies to the right; otherwise one lies at `Mid` or to its left.

The postcondition `Is_Peak (Input, Position)` is proved. The loop keeps two facts:
- the array rises into `Lo` (or `Lo` is the first index);
- it falls out of `Hi` (or `Hi` is the last index).

When `Lo = Hi`, these two facts make it a peak.

Cost: O(log N). `Probe_Count` is 0 .. 5 = log2 32, so the bound on comparisons is proved: a ghost table bounds `Hi - Lo` by 31 / 2 ** probes. `tests.adb` and the own checks also assert at most floor (log2 N) + 2 comparisons. The tests accept any peak, and they check the exact index only where the peak is unique.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (22 checks).

`make test` runs `tests.adb` and the folder's own checks: 220,265 checks against the set of all peaks (see `tests/SOURCES.txt`).

The first version (Length 8, although this README said n <= 32) was a linear arg-max over the whole array, with no contract. Its answer, the global maximum, is a peak, but finding it costs N - 1 comparisons. Commit 17a4e1f4 added a comparison counter and a test asserting the log bound. That test fails on the old scan (31 comparisons for N = 32).
