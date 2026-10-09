# Ada-SPARK-Zigzag-Iterator-Stub

Zigzag iterator over two lists of up to 1000 values each: A (1), B (1), A (2), B (2), ...; once one list is used up, the rest of the other. (The folder name keeps its old `-Stub` suffix; the code is the full iterator.)

Contracts: model functions `A_Size`, `B_Size`, `A_Taken`, `B_Taken`, `A_Elem`, `B_Elem`; `Next` returns the next value of A exactly when `Next_From_A` (A has one left, and B is used up or has given as many values as A), otherwise the next value of B, and advances that list by one; a type invariant keeps `A_Taken <= A_Size`, `B_Taken <= B_Size`.

## Verification

```text
make test
make prove
```

`make prove`: SPARK Silver plus the functional Posts, level-2 cvc5 (70 checks). Tests: `tests.adb` (original) and `own_checks.adb` (independent "A (I) then B (I)" reference; every pair of lengths 0 .. 12, the 1000 extremes, 3,000 random pairs, seed 20261009).
