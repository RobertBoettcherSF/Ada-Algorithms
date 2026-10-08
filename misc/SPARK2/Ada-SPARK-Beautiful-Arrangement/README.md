# Ada-SPARK-Beautiful-Arrangement

A small bounded Ada/SPARK exercise with SPARK_Mode enabled.

Run `make test` and `make prove` after sourcing the SPARK toolchain environment.

`Is_Beautiful (A, N)` is True when `A (1 .. N)` is a permutation of `1 .. N`
and, at every position `I`, `A (I)` is divisible by `I` or `I` by `A (I)`.
