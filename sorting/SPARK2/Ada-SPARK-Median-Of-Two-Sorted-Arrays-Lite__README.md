# Ada-SPARK-Median-Of-Two-Sorted-Arrays-Lite

Compute a bounded integer median after merging two small arrays. The implementation uses fixed-size bounded inputs (n <= 32) and is written in SPARK.

## Checks

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors.
