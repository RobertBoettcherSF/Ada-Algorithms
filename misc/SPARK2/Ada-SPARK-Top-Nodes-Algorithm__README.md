# Top Nodes Algorithm

A tiny bounded Ada SPARK implementation of a Top Nodes Algorithm. The package is deliberately small so the ranking rule is easy to inspect and verify.

## Build and test

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```

The proof command uses SPARK Level 2 with cvc5, warnings-as-errors, and checks-as-errors.
