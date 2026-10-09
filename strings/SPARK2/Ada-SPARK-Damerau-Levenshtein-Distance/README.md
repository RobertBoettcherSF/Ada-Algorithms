# Ada/SPARK Damerau-Levenshtein Distance

Bounded optimal-string-alignment Damerau-Levenshtein distance for strings of at most
4 characters. The rolling three-row dynamic program includes adjacent transpositions.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).

## Index convention

The input arrays may start at any index (First-relative): the precondition only
bounds their lengths. `tests.adb` checks that the same data stored at shifted
origins, including storage that ends at `Positive'Last`, gives the same result.
