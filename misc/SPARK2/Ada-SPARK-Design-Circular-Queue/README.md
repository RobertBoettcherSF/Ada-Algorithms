# Ada-SPARK-Design-Circular-Queue

A bounded FIFO queue (`Capacity = 4` items of `Value = -100 .. 100`) in a ring buffer, written in
Ada 2022 / SPARK.

- `Enqueue (Q, V)` adds V at the back (`Pre => Length (Q) < Capacity`), `Dequeue (Q)` removes the front
  item and `Front (Q)` returns it (`Pre => Length (Q) > 0`). `Element (Q, I)` is the I-th item from the
  front.
- Every operation has a full postcondition: Enqueue keeps the queued items in order and puts V last;
  Dequeue moves every remaining item up one place; Front is `Element (Q, 1)`. A `Type_Invariant` ties the
  ring indices together (`Tail` is the slot just after the newest item). Proved at level 4 and with the
  Silver command (gnatprove 16.1.0, 53 checks, proof warnings on: none), and with `make prove`.
- Before 2026-10-09 the operations had no postconditions, and Enqueue / Dequeue carried guards
  (`if Size < Capacity`, `if Size > 0`) that the preconditions already excluded. Without assertion
  checks, Enqueue on a full queue would have overwritten the oldest item silently; the guards are gone and
  the contracts state the behaviour instead.

```sh
make test    # hand-worked cases + own_checks.adb (model-based, tests/SOURCES.txt)
make prove   # gnatprove on proof.gpr
```
