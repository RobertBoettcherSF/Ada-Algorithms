# Ada-SPARK-Design-A-Stack-With-Increment-Operation

A small bounded SPARK implementation of the Design A Stack With Increment Operation exercise.

## Verification

```text
make test
make prove
```

Proof uses GNATprove level 2 with cvc5, warnings and checks treated as errors.

## V&V sweep notes (agent A3)

`Increment` used to skip, silently and element by element, any value that
would pass `Value'Last` (1000), so one call could raise some elements and
not others. It now has the precondition `Fits (S, Bottom, By)` and adds
`By` to every affected element (failing test first, then the fix;
`make prove`: 21 checks proved). The test build now uses `-gnatwa -gnata`.
Tests: hand-worked cases in `tests.adb` and an array model in
`own_checks.adb` (see `tests/SOURCES.txt`).
