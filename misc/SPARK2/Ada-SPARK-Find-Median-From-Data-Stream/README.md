# Ada-SPARK-Find-Median-From-Data-Stream

A bounded stream median primitive that sorts at most eight observed values.

The implementation is Ada 2022 with `SPARK_Mode => On`.  The input bounds are intentionally tiny so the example is suitable for full level-2 proof.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`Median (Input, Count)` looks at `Input (1 .. Count)`. For an odd `Count`
it is the middle value in sorted order. For an even `Count` it is the two
middle values added and divided by 2 with Ada integer division, which
truncates toward zero (for example the median of -3 and 0 is -1).
