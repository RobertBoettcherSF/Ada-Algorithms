# Ada-SPARK-Meeting-Rooms-II

A bounded SPARK helper for taking the maximum simultaneous room demand.
The demand bound is `0 .. 32`.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
