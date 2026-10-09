# Ada-SPARK-Super-Ugly-Number-Stub

PLACEHOLDER: answers come from a 24-entry constant table, nothing is computed; see H114

Bounded SPARK implementation of a super-ugly number sequence.

The package is bounded and compiled with `SPARK_Mode => On`.

## Verification

```text
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

Proof uses GNATprove level 2 with cvc5, warnings-as-errors, and checks-as-errors.
