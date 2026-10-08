# Ada-SPARK-Queue-Reconstruction-By-Height

A bounded SPARK helper for the valid insertion position represented by the
number of people ahead. Queue positions are limited to `0 .. 32`.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
