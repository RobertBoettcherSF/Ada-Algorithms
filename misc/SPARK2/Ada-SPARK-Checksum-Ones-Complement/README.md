# Ada-SPARK-Checksum-Ones-Complement

A bounded Ada/SPARK implementation of Checksum Ones Complement.

## Checks

```sh
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings-as-errors, and checks-as-errors.

## Index convention

The input array may start at any index (First-relative): the precondition only
bounds its length. `tests.adb` checks that the same data stored at shifted
origins, including storage that ends at `Positive'Last`, gives the same result.
