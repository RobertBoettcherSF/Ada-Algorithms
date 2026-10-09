# Ada/SPARK LZ77

A tiny bounded LZ77 teaching baseline: the literal-only encoder returns the encoded
length. It keeps the window contract explicit (`Window_Size = 4`) while leaving the
back-reference tuple as the next exercise.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).

## Index convention

The input arrays may start at any index (First-relative): the precondition only
bounds their lengths. `tests.adb` checks that the same data stored at shifted
origins, including storage that ends at `Positive'Last`, gives the same result.
