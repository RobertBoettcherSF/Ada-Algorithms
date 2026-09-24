# Ada-SPARK-Kth-Smallest-BST-Stub

Bounded SPARK implementation of k-th smallest BST.

## Verification

```text
make test
make prove
```

The package uses `pragma SPARK_Mode (On)` and fixed-size storage, with Level 2 proof via cvc5.
