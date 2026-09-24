# Ada-SPARK-Heap-Push-Pop

A bounded SPARK implementation of bounded min-heap push and pop.

## Verification

```text
make test
make prove
```

The package uses `SPARK_Mode => On`; proof is run at level 2 with cvc5.
