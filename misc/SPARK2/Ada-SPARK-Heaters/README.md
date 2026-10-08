# Ada-SPARK-Heaters

Compute the minimum heater radius covering bounded house positions. The implementation uses fixed-size bounded inputs (n <= 32) and SPARK_Mode On.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors.
