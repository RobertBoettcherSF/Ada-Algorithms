# Shortest Remaining Time

A tiny bounded Ada SPARK implementation of Shortest Remaining Time. The package is deliberately small so the scheduling rule is easy to inspect and verify.

## Build and test

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```

The proof command uses SPARK Level 2 with cvc5, warnings-as-errors, and checks-as-errors.
