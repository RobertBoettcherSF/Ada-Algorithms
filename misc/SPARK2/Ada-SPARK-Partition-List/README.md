# Ada-SPARK-Partition-List

A bounded, array-backed Ada SPARK implementation of the  Partition List exercise. The list capacity is 16 and uses no access types.

```text
make test
```

`make test` runs GNATprove at proof level 2 with cvc5 and then the executable checks.
