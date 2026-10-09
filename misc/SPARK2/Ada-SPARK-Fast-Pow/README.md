# Ada-SPARK Fast Pow

Fast modular exponentiation in SPARK. `Power_Mod (B, E, M)` returns B ** E mod M for any `Natural` B and E and any `Positive` M, together with the number of steps. It uses left-to-right square-and-multiply over the 31 bits of E: each step squares the running value and multiplies by B when the bit is set. That is exactly 31 steps for every call, instead of E multiplications. Every intermediate is below M <= 2 ** 31 - 1, so each product is below 2 ** 62 and is computed in `Long_Long_Integer`.

**Range widened:** the first version was a case table of exact powers for bases 0 .. 5 and exponents 0 .. 12, with no modulus. The old answers are still checked, exactly, with modulus 2 ** 31 - 1 (they are all below it). Exact non-modular powers above `Natural` are out of scope.

The proved contract is `Value = Mod_Pow (B, E, M)` and `Steps = 31` (35 checks). The ghost `Mod_Pow` is the halving definition B ** 0 = 1, B ** E = (B ** (E / 2)) ** 2 * (B if E is odd). The loop invariant keeps E = Prefix * 2 ** (I + 1) + Rest, where Prefix is the bits already processed.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
