# Ada-SPARK-Sorted-Array-To-BST

Bounded SPARK implementation of sorted array to BST.

`Build` turns `Input (1 .. Length)` (at most 31 values) into a
height-balanced tree whose in-order sequence is the input: each subrange
`First .. Last` puts `Input (First + (Last - First) / 2)` at its root.
Nodes are stored by heap position (root 1, children `2 * N` and
`2 * N + 1`), so 31 nodes always fit in five levels. The input is not
required to be sorted: `Is_BST` reports whether the result is a binary
search tree, checking every node against the bounds set by all of its
ancestors (equal values give `False`). `Height` and `Contains` (a
binary-search descent) observe the shape and the stored values.

Earlier versions kept separate child-link arrays and checked only each
parent against its two children, so `1 2 5 4 6 7 8` (5 in the left
subtree of 4) was reported as a BST; `tests.adb` keeps that case.

## Verification

```text
make test
make prove
```

The package uses `pragma SPARK_Mode (On)` and fixed-size storage, with Level 2 proof via cvc5.
