# Ada-SPARK-Odd-Even-Merge-Sort

Batcher's odd-even merge sort of an `Input_Array` of eight values in `0 .. 31`: the 19-comparator network. Pairs are sorted, merged into sorted 4-blocks, and the two 4-blocks merged (distance 4, then 2 on the middle, then neighbours); every comparator puts the smaller value at the lower index. `Sort_Traced` also returns the comparators in the order they ran; `Merge_Network` lists them.

Proof (SPARK, `make prove`, level 2, cvc5 + z3, timeout 10 s, 116 checks): no run-time error and the full Post: the result is sorted, a permutation of the input (`Is_Perm`, value counts, swap lemmas), and the trace equals `Merge_Network`. Intermediate assertions give each comparator layer's result as min / max of a ghost snapshot.

Tests: `tests.adb` (original) and `own_checks.adb`: the trace equals the textbook network generated in the test by Batcher's iterative rule and the result equals that network applied by an own `Apply`; every 0/1 input, edge shapes, 3,000 random inputs against an insertion sort and value counts (seed 20261008).

```sh
make test
make prove
```
