# Ada-SPARK-Wiggle-Sort

A bounded one-pass wiggle transformation with adjacent ordering checks.

The implementation is Ada 2022 with `SPARK_Mode => On`.  The input bounds are intentionally tiny so the example is suitable for full level-2 proof.

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```
