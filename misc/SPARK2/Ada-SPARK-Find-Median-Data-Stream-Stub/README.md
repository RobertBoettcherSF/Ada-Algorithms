# Ada-SPARK-Find-Median-Data-Stream-Stub

PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Find-Median-Data-Stream implementation; see PROOFS.csv stub

Bounded SPARK median finder for a finite data stream.

The package is bounded and compiled with `SPARK_Mode => On`.

## Verification

```text
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

Proof uses GNATprove level 2 with cvc5, warnings-as-errors, and checks-as-errors.
