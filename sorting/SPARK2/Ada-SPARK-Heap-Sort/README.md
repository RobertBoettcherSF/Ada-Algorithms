# Ada-SPARK-Heap-Sort

A bounded Ada 2022 SPARK heapsort. `Heapify` builds a max-heap in place (Floyd: sift down from the last parent to the root). `Sort` copies the input, calls `Heapify`, then repeatedly swaps the root with the last live slot and sifts down. A parent is at least both children; the children of `i` are `2*i` and `2*i+1`. Arrays stay eight values in `0 .. 31` (`Index` is `1 .. 8`).

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
