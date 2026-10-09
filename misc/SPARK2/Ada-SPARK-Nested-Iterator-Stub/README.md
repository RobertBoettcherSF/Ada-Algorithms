# Ada-SPARK-Nested-Iterator-Stub

Flatten-nested-list iterator. A nested list of integers and nested lists (up to 1000 entries) is built left to right with `Add` (an integer), `Open_List` and `Close_List`; the iterator returns its integers flattened, left to right, stepping over list starts and ends, so empty lists (also nested ones such as `[[], [[]]]`) contribute nothing and `Has_Next` is false when only empty lists remain. (The folder name keeps its old `-Stub` suffix; the code is the full iterator.)

Contracts (proved): `Add` / `Open_List` / `Close_List` append one entry and keep the earlier ones (`Same_Prefix`), `Depth` counts open lists, `Create` (all lists closed) copies the entries and points at the first integer entry, `Next` returns `Int (Pos)` and moves `Pos` to the next integer entry with no integer entry in between; type invariants keep `Pos` on an integer entry or one past the end.

## Verification

```text
make test
make prove
```

`make prove`: SPARK Silver plus the functional Posts, level-2 cvc5 (149 checks). Tests: `tests.adb` (original) and `own_checks.adb` (every well-formed sequence of up to 9 Add / Open_List / Close_List steps, 2,000 random structures of up to 1000 entries, against the integers in the order added, seed 20261009).
