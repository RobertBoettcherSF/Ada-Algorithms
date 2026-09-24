# Ada-SPARK-Hand-Of-Straights-Stub

Bounded SPARK checker for grouping a hand into consecutive straights.

The package is bounded and compiled with `SPARK_Mode => On`.

## Verification

```text
source /home/box/deps/spark/env.sh
make test
make prove
```

Proof uses GNATprove level 2 with cvc5, warnings-as-errors, and checks-as-errors.
