# Ada/SPARK Zobrist Hashing

A bounded position-sensitive XOR hash. Each character/position pair receives a
deterministic 32-bit key, illustrating the Zobrist construction without a large table.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).
