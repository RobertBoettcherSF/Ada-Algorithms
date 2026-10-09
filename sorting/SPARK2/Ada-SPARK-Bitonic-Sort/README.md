# Ada-SPARK-Bitonic-Sort

Bitonic sort (Batcher) of an `Input_Array` of eight values in `0 .. 31`: the 24-comparator bitonic network. Blocks of 2, then 4, then 8 are sorted; each step first compares the two halves of a block mirror-wise, then runs the half-cleaners; every comparator puts the smaller value at the lower index. `Sort_Traced` also returns the comparators in the order they ran; `Bitonic_Network` lists them.

Proof (SPARK, `make prove`, level 2, cvc5 + z3, timeout 10 s): no run-time error and the full Post: the result is sorted, a permutation of the input (`Is_Perm`, value counts, swap lemmas), and the trace equals `Bitonic_Network`. Intermediate assertions state each stage's result (sorted pairs, sorted 4-blocks, halves ordered after the mirror step, quarters ordered after the first half-cleaner).

Tests: `tests.adb` (original) and `own_checks.adb`: the trace equals the textbook network generated in the test from Batcher's rule and the result equals that network applied by an own `Apply`; every 0/1 input, edge shapes, 3,000 random inputs against an insertion sort and value counts (seed 20261008).

```sh
make test
make prove
```
