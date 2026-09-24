# Ada-SPARK-Kth-Largest-Array

A bounded SPARK implementation of select the k-th largest item in a bounded array.

## Verification

```text
make test
make prove
```

The package uses `SPARK_Mode => On`; proof is run at level 2 with cvc5.
