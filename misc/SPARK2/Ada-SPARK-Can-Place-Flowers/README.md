# Ada-SPARK-Can-Place-Flowers

A bounded SPARK capacity check for placing a requested number of flowers.
Counts are limited to `0 .. 32`.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
