# Ada-SPARK-Quick-Sort

A bounded Ada 2022 SPARK quicksort. `Sort` partitions around the last element of the live slice and recurses on both sides. One partition (Lomuto) leaves values at or below the pivot on its left and values at or above the pivot on its right. Arrays stay eight values in `0 .. 31` (`Index` is `1 .. 8`).

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
