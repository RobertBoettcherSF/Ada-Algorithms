# Ada-SPARK-Logger-Rate-Limiter-Lite

A bounded logger rate limiter.

The implementation uses bounded types and `SPARK_Mode => On`.

```text
make test
make prove
```

Proof uses GNATprove level 2 with cvc5 and warnings/checks treated as errors.
