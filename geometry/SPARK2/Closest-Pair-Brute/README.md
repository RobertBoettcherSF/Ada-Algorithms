# Closest-Pair-Brute

Smallest squared Euclidean distance between two of the first
`Number_Of_Points` points (1 .. 16, coordinates -1000 .. 1000), by
trying every pair, in SPARK. `Distance_Squared` is
`(X1 - X2) ** 2 + (Y1 - Y2) ** 2` in `Long_Long_Integer` (at most
8_000_000). With one point there is no pair and `Find` returns
`Long_Long_Integer'Last`. Repeated points give 0.

## Verification

```text
make test    # -gnatwa -gnat2022 -gnata
make prove   # Level 2, cvc5
```

Own checks: `own_checks.adb`, sources in `tests/SOURCES.txt`.
