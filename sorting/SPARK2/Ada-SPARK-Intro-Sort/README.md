# Ada-SPARK-Intro-Sort

A bounded Ada 2022 SPARK introsort. `Sort` partitions the live slice around its last element (Lomuto) and recurses on both sides while the depth budget lasts. A slice of two values is ordered with one compare-exchange. The depth budget is 6 (`2 * floor(log2(8))`). Each recursive call removes the pivot, and a slice of length at most 2 does not recurse, so on an array of length 8 that budget is never exhausted. That is ordinary introsort behaviour at this bound, not a missing heapsort. `Sort_Limited` takes an explicit budget: 0 heapsorts the whole array, and a budget below 6 heapsorts the slice that runs out of depth. The fallback calls `Heapify` (Floyd max-heap, children `2*i` and `2*i+1`) and then sifts the root out to the end. Arrays stay eight values in `0 .. 31` (`Index` is `1 .. 8`).

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
