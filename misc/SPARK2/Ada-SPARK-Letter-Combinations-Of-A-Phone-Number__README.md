# Ada-SPARK-Letter-Combinations-Of-A-Phone-Number

Bounded ternary count for phone-letter combinations up to twelve digits. The implementation is bounded and compiled with `SPARK_Mode => On`.

## Checks

```text
make test
make prove
```

The proof command runs level-2 GNATprove with cvc5, warnings treated as errors, and checks treated as errors.
