# Ada-SPARK-Tim-Sort

Timsort of an `Input_Array` of eight values in `0 .. 31`, as CPython's `listsort` does it for n < 64 (Objects/listsort.txt): the min-run is then n itself, so the sort is a single run. `count_run` finds the longest ascending (`A (K) <= A (K + 1)`) or strictly descending start, a descending start is reversed in place, and `binarysort` inserts the remaining values one by one at the place found by binary search after any equal keys (bisect right, stable). No merge happens at this size; run merging (min-run, the run stack, galloping) only starts at 64 elements and is not implemented here. `Sort_Traced` also returns the comparisons as they ran, the first run's length and whether it was reversed.

Proof (SPARK, `make prove`, level 2, cvc5 + z3, timeout 10 s, 248 checks): no run-time error and the full Post: the result is sorted and a permutation of the input (`Is_Perm`, value counts, swap lemmas; values are moved by adjacent exchanges), `Reversed` is whether the input starts strictly descending, and the input's first `Run` values are ascending, or strictly descending when reversed.

Tests: `tests.adb` (original) and `own_checks.adb`: trace, run and reversal equal an own model of CPython's small-n Timsort on every 0/1 input, 3,000 random inputs and fixed shapes; edge shapes and random inputs against an insertion sort and value counts (seed 20261008).

```sh
make test
make prove
```
