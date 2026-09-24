# Ada-SPARK-Sorted-Array-To-BST

Bounded SPARK implementation of sorted array to BST.

## Verification

```text
make test
make prove
```

The package uses `pragma SPARK_Mode (On)` and fixed-size storage, with Level 2 proof via cvc5.
