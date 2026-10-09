# Binary-Insertion-Sort

Binary insertion sort, in SPARK. `Sort (Input)` sorts 8 values in 0 .. 31 and returns the sorted array and the number of comparisons of two values (`Probes`).

Each element in turn is inserted into the sorted prefix before it. Its place is found by binary search: the first position in the prefix that holds a larger value (so equal values keep their order). The element then moves down to that place by swaps with its larger neighbours.

The postcondition is proved: the result is sorted, and every value occurs in it as often as in the input (`Occ`, a recursive ghost count). `Lemma_Swap` shows that a swap of neighbours keeps every count. The insertion step keeps a ghost copy of the array from before the moves, which ties the moved elements to their old places.

Cost: comparisons O(N log N), moves O(N ** 2) (as for any insertion sort on an array). Inserting the I-th element searches I insertion points, which takes at most floor (log2 (I - 1)) + 1 comparisons; a ghost table `Bits` bounds each search and `Sum_Bits` the total, so `Probe_Count` 0 .. 17 is proved. `tests.adb` asserts the bound, computed as the sum of floor (log2 I) + 1 over I = 1 .. 7.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (126 checks), on `proof.gpr` (the package only).

`make test` runs `tests.adb` (the original example, ascending, descending, repeats, all equal) and the folder's own checks (see `tests/SOURCES.txt`).

The first version made 8 fixed passes of neighbour compare-exchange (a bubble sort, 56 comparisons), with no binary search, no contract and no README. The failing test that came first added a comparison counter and the bound. It fails on the old code (56 comparisons, bound 17).
