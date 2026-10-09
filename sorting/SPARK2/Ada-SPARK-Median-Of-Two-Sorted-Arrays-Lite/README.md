# Ada-SPARK-Median-Of-Two-Sorted-Arrays-Lite

Median of two sorted arrays, in SPARK. `Left` and `Right` each hold 16 values in 0 .. 100 and never decrease (the subtype predicate of `Sorted_Array`). Their 32 values have two middle ones, the 16th smallest (`Lower`) and the 17th smallest (`Upper`), counting repeats. `Median` returns both, their mean rounded down (`Median`, as the original returned it) and the number of comparisons of two values (`Probes`).

It does not merge the arrays. The lower half of the 32 values takes some number I from the start of `Left` and J = 16 - I from the start of `Right`. A binary search finds the smallest I for which `Right (J) <= Left (I + 1)` (or I = 16). For that I, also `Left (I) < Right (J + 1)`, because the cut I - 1 failed. Then `Lower` is the larger of `Left (I)` and `Right (J)` and `Upper` the smaller of `Left (I + 1)` and `Right (J + 1)`.

The postcondition is proved: fewer than 16 values are below `Lower` and at least 16 are <= it, fewer than 17 are below `Upper` and at least 17 are <= it; that is, they are the 16th and the 17th smallest. The counts are the recursive ghost functions `Count_Lt` and `Count_Le`. `Lemma_Lt_At_Most` (everything after position I is >= X, so at most I values are < X) and `Lemma_Le_At_Least` (A (I) <= X, so at least I values are <= X) give each bound from the two facts about the cut.

Cost: O(log N). There are 17 possible cuts, so at most 5 comparisons find the cut (a ghost table bounds the search range by 16 halved per comparison), and at most 2 more pick `Lower` and `Upper`. `Probe_Count` 0 .. 7 is proved. `tests.adb` asserts at most floor (log2 32) + 2 = 7.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (95 checks), on `proof.gpr` (the package only).

`make test` runs `tests.adb` (the original example 1 3 8 10 / 2 4 9 12 padded to 16 values each, one array wholly below the other in both orders, odd / even interleaved, all equal) and the folder's own checks: 17,004 checks against an insertion sort of all 32 values, exact counts on hand-worked pairs and a measured worst case of 6 comparisons (see `tests/SOURCES.txt`).

The first version copied both 4-element arrays and selection-sorted all 8 values, with no contract and no sortedness requirement; this README said n <= 32. The failing test that came first grew the arrays to 16 values, added a comparison counter and asserted the log bound. It fails on the old code (496 comparisons for 32 values).
