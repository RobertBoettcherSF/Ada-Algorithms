# Ada/SPARK Trigram Search

A bounded linear scan for a three-character query (a trigram). Text is limited to
16 characters and the implementation has no dynamic allocation.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).

## Index convention

The input arrays may start at any index (First-relative): the precondition only
bounds their lengths. `tests.adb` checks that the same data stored at shifted
origins, including storage that ends at `Positive'Last`, gives the same result.
