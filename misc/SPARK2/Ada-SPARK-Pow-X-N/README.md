# Ada-SPARK-Pow-X-N

Integer power X ** N by repeated squaring, in SPARK, for every `Integer` X and every `Natural` N.

`Power (X, N, Result, Ok)` sets `Ok` to True exactly when X ** N fits in `Integer`; `Result` is then X ** N, and 0 otherwise.

**Range widened:** the first version was a case table for X in -2 .. 2 and N in 0 .. 5. The only limit now is the result type, and the code itself decides it. X ** N fits for every N when X is -1, 0 or 1. Otherwise it never fits for N >= 32, because abs X ** N >= 2 ** 32 (`Lemma_Big`). In between, the loop finds the overflow while it multiplies and squares (a base outside -46_340 .. 46_340 cannot be squared again, since 46_341 ** 2 > 2 ** 31).

The proved contract (353 checks): `Ok = Fits_Power (X, N)` and, when `Ok`, `Result = Pow (X, N)`. Here `Pow` is a ghost power over `Big_Integer`, defined by halving N. `Fits_Power` is "Pow (X, N) fits in Integer", with a short cut for abs X >= 2 and N >= 32 so that the contract stays cheap to check at run time. `Lemma_Big` proves that the short cut gives the same answer. The proof also covers the absence of overflow and the termination of the loop (`Loop_Variant`).

The tests compare against two own naive references. The library's `Big_Integers."**"` is not one of them, because it gets the sign wrong for negative bases with GNAT 14.2 and 12.2 (see `tests/SOURCES.txt`).

## Checks

```text
make test
make prove
```

`make prove` runs level-2 GNATprove with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks.
