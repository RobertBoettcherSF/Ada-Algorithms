# Ada/SPARK Zobrist Hashing

A bounded position-sensitive XOR hash. Each character/position pair receives a
deterministic 32-bit key, illustrating the Zobrist construction without a large table.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).

## Index convention

The input arrays may start at any index (First-relative): the precondition only
bounds their lengths. `tests.adb` checks that the same data stored at shifted
origins, including storage that ends at `Positive'Last`, gives the same result.
