# Ada-SPARK-Design-Hit-Counter-Lite

A bounded hit counter.

The implementation uses bounded types and `SPARK_Mode => On`.

```text
make test
make prove
```

Proof uses GNATprove level 2 with cvc5 and warnings/checks treated as errors.
