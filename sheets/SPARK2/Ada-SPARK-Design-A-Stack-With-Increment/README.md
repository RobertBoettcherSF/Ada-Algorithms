# Ada-SPARK-Design-A-Stack-With-Increment

A bounded stack with bottom increment.

The implementation uses bounded types and `SPARK_Mode => On`.

```text
make test
make prove
```

Proof uses GNATprove level 2 with cvc5 and warnings/checks treated as errors.
