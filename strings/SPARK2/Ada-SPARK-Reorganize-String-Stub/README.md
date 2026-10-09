# Ada-SPARK-Reorganize-String-Stub

PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Reorganize-String implementation; see PROOFS.csv stub

Bounded SPARK character rearrangement that interleaves the two sorted halves.

The package is bounded and compiled with `SPARK_Mode => On`.

## Verification

```text
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

Proof uses GNATprove level 2 with cvc5, warnings-as-errors, and checks-as-errors.
