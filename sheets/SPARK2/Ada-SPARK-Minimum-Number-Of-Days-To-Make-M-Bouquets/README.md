# Ada-SPARK-Minimum-Number-Of-Days-To-Make-M-Bouquets

Find the earliest day on which one bounded consecutive bouquet can bloom. The implementation uses fixed-size bounded inputs (n <= 32) and SPARK_Mode On.

## Checks

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors.
