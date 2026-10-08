# Ada-SPARK-LRU-Cache-Lite

A bounded SPARK array-backed cache map with deterministic insertion and update.

All storage is bounded to 16 entries and uses SPARK_Mode (On).

## Checks

```text
make test
make prove
```

Least-recently-used cache of 16 entries. `Put` stores a value and makes
the key most recently used; a new key on a full cache first evicts the
least recently used entry. `Get` returns a value and counts as a use;
`Lookup` and `Contains` only read. `Get` and `Lookup` require the key to
be present (precondition).
