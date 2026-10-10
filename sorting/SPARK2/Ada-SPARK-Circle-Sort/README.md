# Ada-SPARK-Circle-Sort

Circle sort of an `Input_Array` of eight values in `0 .. 31`. A pass on `Lo .. Hi` compares the mirrored pairs (`Lo + I`, `Hi - I`), exchanging when out of order, then recurses on both halves; for 8 values one pass is the 12 comparisons of `Circle_Pass`. Passes repeat until one makes no exchange. `Sort_Traced` also returns the comparisons as they ran and the number of passes.

Proof (SPARK, `make prove`, level 2, cvc5 + z3, timeout 10 s, 231 checks): no run-time error and the full Post: the result is sorted, a permutation of the input (`Is_Perm`, value counts, swap lemmas), the trace is `Circle_Pass` once per pass, and there are at most `Inversions (Input) + 1` passes (every exchange removes at least one inversion; this is also the loop variant). A pass without exchanges leaves a sorted array because its comparisons include every neighbouring pair.

Tests: `tests.adb` (original) and `own_checks.adb`: trace, pass count and result equal an own recursive circle-sort model on every 0/1 input and 3,000 random inputs; edge shapes and random inputs against an insertion sort and value counts (seed 20261008). Circle sort is not oblivious (the pass count depends on the data), so the trace is checked per input rather than by the 0-1 principle.

```sh
make test
make prove
```
