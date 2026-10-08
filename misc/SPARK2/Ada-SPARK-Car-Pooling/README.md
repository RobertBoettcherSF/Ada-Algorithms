# Ada-SPARK-Car-Pooling

A bounded car-pooling capacity check over eight trip records.

## Verify

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

A trip carries its `People` from stop `Pickup` up to, not including, stop
`Dropoff` (they leave before new passengers board there); a trip with
`Dropoff <= Pickup` occupies no stop. `Feasible (T, Limit)` is True when no
stop has more than `Limit` people on board.
