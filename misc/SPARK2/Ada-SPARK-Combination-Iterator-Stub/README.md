# Ada-SPARK-Combination-Iterator-Stub

Iterator over the K-element combinations of up to 20 items, in lexicographic order of positions (1, 2, ..., K first; N - K + 1, ..., N last). `Next` returns the items at the current positions, then moves the rightmost position that can still move right one step and resets the positions after it. (The folder name keeps its old `-Stub` suffix; the code is the full iterator for any K <= N.)

Contracts: model functions `Item_Count`, `Choose`, `Item`, `Pos`, `Done`; a type invariant keeps `Pos (1) < ... < Pos (K)` with `Pos (J) in J .. N - K + J`; `Next` returns `Item (Pos (J))` for J in 1 .. K and is `Done` exactly after the last combination. Otherwise the new positions are the lexicographic successor (Knuth, TAOCP Vol. 4A, 7.2.1.3): `Pivot (It)` is the rightmost position that can still move right (`Pos (J) < N - K + J`, 0 exactly for the last combination, stated in its Post); positions before it are unchanged, it goes up by one, and the positions after it follow consecutively. The Post states this successor rule; that it is the least larger combination follows from the rule and the type invariant but is not itself a proved statement. `own_checks.adb` checks the positions and the pivot before every `Next` against an independent enumeration.

## Verification

```text
make test
make prove
```

`make prove`: SPARK Silver plus the Posts above, level-2 cvc5 (142 checks). Tests: `tests.adb` (original) and `own_checks.adb` (every N in 1 .. 20 and K in 1 .. N against an independent recursive enumeration, random item values, seed 20261009).
