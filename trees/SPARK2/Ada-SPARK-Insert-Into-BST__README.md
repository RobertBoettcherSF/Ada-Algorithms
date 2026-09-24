# Ada-SPARK-Insert-Into-BST

A bounded SPARK implementation of insert and search in a bounded binary-search-tree model.

## Verification

```text
make test
make prove
```

The package uses `SPARK_Mode => On`; proof is run at level 2 with cvc5.
