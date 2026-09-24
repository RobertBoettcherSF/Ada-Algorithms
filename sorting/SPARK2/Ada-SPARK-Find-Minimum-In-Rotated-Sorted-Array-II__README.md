# Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array-II

Find the minimum element in a bounded rotated sorted array. The implementation uses fixed-size bounded inputs (n <= 32) and SPARK_Mode On.

## Checks

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors.
