# Ada-SPARK-Flash-Sort

Flashsort (K.-D. Neubert, "The Flashsort1 Algorithm", Dr. Dobb's Journal, February 1998) of an `Input_Array` of eight values in `0 .. 31`. With the input's minimum and maximum (nothing to do when they are equal), the class of a key `X` is `1 + ((M - 1) * (X - Min)) / (Max - Min)` with `M = 3` classes (about 0.42 n); class counts and their prefix sums give `L (K)`, the end of class `K`'s region, and the maximum is exchanged into slot 1. The permutation phase is Neubert's cycle leader: from the first slot not yet placed, the key there is dropped at `L (class)`, `L (class)` decreases, and the displaced key is dropped next, until a drop lands on the leader slot; repeated until n - 1 drops. A final straight insertion pass from the top finishes the sort. `Sort_Traced` also returns the slot of every drop in order.

Proof (SPARK, `make prove`, level 2, cvc5 + z3, timeout 10 s, 411 checks): no run-time error and the full Post: the result is sorted and a permutation of the input (`Is_Perm`, value counts, swap lemmas). The permutation phase is proved with ghost class regions: the number of unplaced slots holding a key of class `C` equals the unplaced part of `C`'s region, so every `L (C)` stays inside its region and every drop lands on an unplaced slot.

Tests: `tests.adb` (original) and `own_checks.adb`: the drop slots and the result equal an own model of Flashsort1 (written from the published description with flash / hold variables) on every 0/1 input, edge shapes, 3,000 random inputs (seed 20261008), 3,000 random inputs (seed 20261009) and all 3**8 inputs over `0 .. 2`; every result is sorted, a permutation of the input and equal to an own insertion sort.

```sh
make test
make prove
```
