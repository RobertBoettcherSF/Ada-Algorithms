# Ada-SPARK-First-Bad-Version

Find the first bad version in a bounded status table. The implementation uses fixed-size bounded inputs (n <= 32) and is written in SPARK.

## Checks

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors.
