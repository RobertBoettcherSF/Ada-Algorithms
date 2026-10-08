# Ada-SPARK-Time-Based-Key-Value-Store

A bounded timestamped key-value slot store. Implemented with bounded storage and SPARK_Mode enabled.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
