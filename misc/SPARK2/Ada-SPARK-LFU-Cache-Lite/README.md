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
`Touch` requires the key to be present (precondition). Use counts are
64-bit (`Use_Count`, 0 .. 2**62) and never saturate: `Put` and `Touch`
require the key's count to be below `Max_Uses` = 2**62 (`Below_Max_Uses`),
which is unreachable in practice (2**62 uses; about 146 years at 10**9 uses
per second). `Get` returns the value stored under a present key
(precondition) without counting a use; its postcondition ties the result to
the stored entry (`Key_At` / `Value_At`).
