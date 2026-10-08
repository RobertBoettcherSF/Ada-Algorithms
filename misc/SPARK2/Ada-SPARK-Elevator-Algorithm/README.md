# Elevator Algorithm

A tiny bounded Ada SPARK implementation of an Elevator Algorithm step. The package is deliberately small so the movement rule is easy to inspect and verify.

## Build and test

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

The proof command uses SPARK Level 2 with cvc5, warnings-as-errors, and checks-as-errors.
