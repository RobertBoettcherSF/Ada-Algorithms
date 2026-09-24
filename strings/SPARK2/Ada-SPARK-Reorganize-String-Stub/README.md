# Ada-SPARK-Reorganize-String-Stub

Bounded SPARK character rearrangement that interleaves the two sorted halves.

The package is bounded and compiled with `SPARK_Mode => On`.

## Verification

```text
source /home/box/deps/spark/env.sh
make test
make prove
```

Proof uses GNATprove level 2 with cvc5, warnings-as-errors, and checks-as-errors.
