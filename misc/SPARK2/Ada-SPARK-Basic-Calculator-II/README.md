# Ada-SPARK-Basic-Calculator-II

A small bounded SPARK implementation of the Basic Calculator II exercise:
`Evaluate (Left, Right, Op)` applies one of `+ - * /` (division truncates toward zero).

Operands are of subtype `Operand` (-31 .. 31), so every result fits `Number`
(-1000 .. 1000) and the postcondition states the exact integer result. Larger
operands are rejected by the type (Constraint_Error at the call); earlier versions
silently clamped results such as 1000 * 2 to 1000.

## Verification

```text
make test
make prove
```

Proof uses GNATprove level 2 with cvc5, warnings and checks treated as errors.
Test sources: tests/SOURCES.txt.
