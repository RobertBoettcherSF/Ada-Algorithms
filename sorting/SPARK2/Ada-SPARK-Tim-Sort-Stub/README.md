# Ada-SPARK-Tim-Sort-Stub

A deliberately small bounded Tim-sort stub for SPARK proof experiments.

The implementation is Ada 2022 with `SPARK_Mode => On`.  The input bounds are intentionally tiny so the example is suitable for full level-2 proof.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
