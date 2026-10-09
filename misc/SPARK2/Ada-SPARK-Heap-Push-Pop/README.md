# Ada-SPARK-Heap-Push-Pop

PLACEHOLDER: unsorted array with a linear minimum search and a full re-sort; no heap; see tools/vv/hidden_stub.csv

A bounded SPARK implementation of bounded min-heap push and pop.

## Verification

```text
make test
make prove
```

The package uses `SPARK_Mode => On`; proof is run at level 2 with cvc5.
