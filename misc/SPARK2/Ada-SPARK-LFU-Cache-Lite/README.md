# Ada-SPARK-LFU-Cache-Lite

A bounded SPARK array-backed cache map with explicit usage counters.

All storage is bounded to 16 entries and uses SPARK_Mode (On).

## Checks

```text
make test
make prove
```

Least-frequently-used cache of 16 entries. `Put` and `Touch` count as a
use and make the key most recently used; a new key on a full cache first
evicts the entry with the fewest uses, the least recently used among ties.
`Touch` requires the key to be present (precondition). Use counts stop at
`Natural'Last`.
