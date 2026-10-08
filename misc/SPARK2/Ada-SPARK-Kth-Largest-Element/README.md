# Ada-SPARK-Kth-Largest-Element

A bounded SPARK implementation of kth-largest selection over eight values.

The implementation is Ada 2022 with `SPARK_Mode => On`.  The input bounds are intentionally tiny so the example is suitable for full level-2 proof.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
