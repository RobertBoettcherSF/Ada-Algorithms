# Ada-SPARK-Tim-Sort-Stub

Timsort as CPython's `listsort` runs it (Objects/listsort.txt), without galloping, on any `Value_Array` of up to `Max_Len = 10_000` integers with any `Positive` index range (`Input'Last < Positive'Last`). Runs are the longest ascending (`A (K) <= A (K + 1)`) or strictly descending stretch (reversed in place), extended to `Min_Run (N)` by binary insertion (after equal keys) and pushed on a run stack; after each push `merge_collapse` merges adjacent runs (with the corrected check of the third run from the top) and at the end the stack is merged down to one run. A merge copies the left run to a buffer and merges forward (`merge_lo`). Galloping (exponential search inside a merge) only changes how a merge copies, not which runs are merged, and is not done here. `Sort_Traced` also returns the event log (`Push (base, length)`, `Merge (stack position)`).

Proof (SPARK, `make prove`, level 2, cvc5 + z3, timeout 10 s, 527 checks): no run-time error (the stack holds at most one run per element; lengths and indices bounded by `Max_Len` and `Input'Last < Positive'Last`) and the Post: the result keeps the bounds and is sorted (pairwise `Sorted`). Every run on the stack is sorted and the runs are contiguous from `Input'First` (`Stack_Ok`); count_run / reversal, binary insertion and the merge each prove sortedness of their range and leave the rest unchanged. Partial: the Post does not state that the result is a permutation of the input (`tools/vv/contract_scan.csv`); the tests check it against an insertion sort.

Tests: `tests.adb` (original) and `own_checks.adb` (seed 20261008): `Min_Run` against the listsort.txt values (63 -> 63, 64 -> 32, 65 -> 33, 2048 -> 32, 2112 -> 33) and an own model for N = 0 .. 70; the event log and result equal an own model of the listsort rules on random and duplicate-heavy inputs up to 5,000 values and on inputs built from natural runs; 4,100 random inputs of length 0 .. 40 plus edge cases against an insertion sort. Sources: `tests/SOURCES.txt`.

```sh
make test
make prove
```
