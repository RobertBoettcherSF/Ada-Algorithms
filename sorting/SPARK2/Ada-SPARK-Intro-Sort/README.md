# Ada-SPARK-Intro-Sort

A bounded Ada 2022 SPARK introsort. `Sort` computes one depth budget from the full length, `2 * floor(log2(8)) = 6`, and does not recompute it for a smaller slice. Each recursive call receives that budget minus one.

On a slice longer than the insertion cutoff of 2, the algorithm Lomuto-partitions around the slice's last element and sorts both sides. The cutoff stays 2, so those longer slices are not insertion-sorted. When the remaining depth is 0, the slice is heapsorted instead. With this budget of 6, a slice's length reaches the cutoff while some depth is still left, so `Sort` itself does not take the heapsort branch. `Sort_Limited` with a smaller depth does: depth 0 heapsorts the whole array.

`Partition` is one Lomuto step on the whole array. `Heapify` builds a max-heap on the whole array (a parent is at least both children; the children of `i` are `2*i` and `2*i+1`). The length-8 fallback uses that `Heapify`.

Arrays stay eight values in `0 .. 31` (`Index` is `1 .. 8`).

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
