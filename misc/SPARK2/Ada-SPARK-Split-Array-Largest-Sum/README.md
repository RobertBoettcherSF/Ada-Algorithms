# Ada-SPARK-Split-Array-Largest-Sum

Split array largest sum, in SPARK. `Input` holds 8 values in 1 .. 100. `Largest_Sum (Input, Parts)` cuts `Input` into at most `Parts` contiguous parts so that the largest part sum is as small as possible. It returns that sum and the number of limits it tried (`Probes`). Each try costs one pass over `Input`.

For a limit `L`, the greedy scan starts a new part only when the next element does not fit (`Scan`, `Greedy_Parts`, both recursive expression functions). The answer lies between the largest element and the total, and the search is a binary search over that range of limits.

The postcondition is proved. The returned limit:
- lies in `Max_Element .. Total`;
- has a greedy split that fits in `Parts`;
- is the least such limit: every smaller limit that is still >= the largest element needs more parts.

The proof uses two lemmas:
- `Lemma_Monotone`: a larger limit never needs more parts. It runs both scans side by side and shows the larger limit stays ahead (fewer parts, or as many with a lighter last part).
- `Lemma_Whole`: the total as limit gives one part.

Not proved: that the greedy split uses the fewest parts among all splits, so that the result is the true optimum. The own checks test that claim against every one of the 128 cut sets.

Cost: O(N log 800). `Probe_Count` is 0 .. 10 = ceil (log2 800), so the bound on limits tried is proved: a ghost table bounds `Hi - Lo` by 799 halved once per try. `tests.adb` and the own checks also assert at most floor (log2 800) + 2 tries.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (82 checks).

`make test` runs `tests.adb` and the folder's own checks: 122,593 checks against all 128 cut sets (see `tests/SOURCES.txt`).

The first version tried every limit from the largest element upward (up to 701 passes), with no contract. Its README said n <= 32, but there are 8 values. Commit 78018057 added a try counter and a test asserting the log bound. That test fails on the old scan (15 tries for 7 2 5 10 8 1 3 4 in two parts).
