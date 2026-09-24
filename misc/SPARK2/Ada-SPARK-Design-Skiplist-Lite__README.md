# Ada-SPARK-Design-Skiplist-Lite

A bounded skiplist-inspired ordered collection.

The implementation uses bounded types and `SPARK_Mode => On`.

```text
make test
make prove
```

Proof uses GNATprove level 2 with cvc5 and warnings/checks treated as errors.
