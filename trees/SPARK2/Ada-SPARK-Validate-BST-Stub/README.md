# Ada-SPARK-Validate-BST-Stub

PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Validate-BST implementation; see PROOFS.csv stub

Bounded SPARK implementation of BST validation.

## Verification

```text
make test
make prove
```

The package uses `pragma SPARK_Mode (On)` and fixed-size storage, with Level 2 proof via cvc5.
