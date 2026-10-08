# Ada-SPARK-Insert-Delete-GetRandom-O1

A bounded O(1)-style insert/delete/index container. Implemented with bounded storage and SPARK_Mode enabled.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
