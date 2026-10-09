# Ada-SPARK-Peeking-Iterator-Stub

An iterator over up to 1000 values with look-ahead: `Peek` returns the next value without consuming it, `Next` returns and consumes it, `Reset` goes back to the first value. (The folder name keeps its old `-Stub` suffix; the code is the full iterator.)

Contracts state the result through the model functions `Size`, `Position` and `Element`: `Peek` and `Next` return `Element (It, Position (It) + 1)`, `Next` advances `Position` by one, `Reset` sets it to 0, and the values never change; a type invariant keeps `Position <= Size`.

## Verification

```text
make test
make prove
```

`make prove`: SPARK Silver plus the functional Posts above, level-2 cvc5 (51 checks). Tests: `tests.adb` (original) and `own_checks.adb` (every length 0 .. 1000 walked to the end; 2,000 random Has_Next / Peek / Next / Reset traces against a plain reference cursor, seed 20261009).
