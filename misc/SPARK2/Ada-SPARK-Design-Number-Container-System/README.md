# Ada-SPARK-Design-Number-Container-System

A fixed-capacity number container with bounded storage. Implemented with bounded storage and SPARK_Mode enabled.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`Add` requires a free slot (`Length (C) < Capacity`) and `Remove_Last`
requires a non-empty container (`Length (C) > 0`). Both conditions are
preconditions, checked at run time, so a full or empty container rejects
the call instead of ignoring it or answering 0. Note: this is a bounded
stack with a membership test; it does not implement the index-to-number
mapping that the name suggests.
