# Ada-SPARK-Convert-Sorted-Array-To-BST

Convert a sorted array to a height-balanced BST: `Build_From (A)` for A (1 .. N), N up to 1,000, builds the tree in an array pool (no access types), node 1 the root, nodes numbered in preorder. Node K covers the array positions `Lo (K) .. Hi (K)` and holds the middle one, `A (Lo + (Hi - Lo) / 2)`; its left subtree covers the part before, its right subtree the part after. So the in-order walk is A (a BST when A is sorted) and the two subtree sizes of every node differ by at most 1. The original 7-element `Build` calls it (root 4, node 7 holds 7, as before).

Proof (SPARK, `make prove`, cvc5 level 2, 57 checks): no run-time error and the Post: the root covers 1 .. N, and every node 1 .. N is the balanced-split node of its range, with the exact child numbers and child ranges (`Node_Ok`). The in-order and balance facts follow from these by induction over the ranges; that induction itself is not a proved lemma, `own_checks.adb` checks it directly.

Tests: `tests.adb` (original) and `own_checks.adb` (every node reached once from the root, in-order walk = A, subtree heights differ by <= 1, height = ceil (log2 (N + 1)); exhaustive N = 0 .. 300, 500 random sorted arrays with duplicates, N up to 1,000; seed 20261009).

```text
make test
make prove
```
