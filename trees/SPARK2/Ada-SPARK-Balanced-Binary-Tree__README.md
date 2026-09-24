# Ada-SPARK-Balanced-Binary-Tree

Bounded SPARK implementation of balanced binary tree.

## Verification

```text
make test
make prove
```

The package uses `pragma SPARK_Mode (On)` and fixed-size storage, with Level 2 proof via cvc5.
