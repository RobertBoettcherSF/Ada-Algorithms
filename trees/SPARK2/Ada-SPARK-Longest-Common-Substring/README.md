# Ada/SPARK Longest Common Substring

A bounded rolling-row dynamic program for the longest contiguous common substring.
Inputs are limited to 4 characters so the proof state stays approachable.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).

## Index convention

The input arrays may start at any index (First-relative): the precondition only
bounds their lengths. `tests.adb` checks that the same data stored at shifted
origins, including storage that ends at `Positive'Last`, gives the same result.
