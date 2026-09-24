# Ada-SPARK-BST-Insert-Search

Bounded SPARK implementation of BST insert/search.

## Verification

```text
make test
make prove
```

The package uses `pragma SPARK_Mode (On)` and fixed-size storage, with Level 2 proof via cvc5.
