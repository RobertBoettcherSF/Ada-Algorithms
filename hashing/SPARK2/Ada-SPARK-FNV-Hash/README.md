# Ada/SPARK FNV-1a Hash

A bounded Fowler-Noll-Vo 32-bit FNV-1a hash over Ada characters. The modular hash
type makes wraparound explicit and avoids unchecked integer overflow.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).

## Index convention

The input array may start at any index (First-relative): the precondition only
bounds its length. `tests.adb` checks that the same data stored at shifted
origins, including storage that ends at `Positive'Last`, gives the same result.
