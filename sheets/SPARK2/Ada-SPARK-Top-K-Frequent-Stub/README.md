# Ada-SPARK-Top-K-Frequent-Stub

A bounded SPARK implementation of return the most frequent values from a bounded array.

## Verification

```text
make test
make prove
```

The package uses `SPARK_Mode => On`; proof is run at level 2 with cvc5.
