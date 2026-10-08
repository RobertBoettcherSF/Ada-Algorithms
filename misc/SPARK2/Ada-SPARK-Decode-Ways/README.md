# Ada-SPARK-Decode-Ways

Decode Ways in SPARK: `Count (Data, Length)` is the number of ways to split `Data (1 .. Length)` into codes
1 .. 9 (one digit) and 10 .. 26 (two digits), by the usual two-variable dynamic programme.

- Strings are 1 .. 29 digits (`Input`): a string of N digits has at most Fib (N + 1) decodings (all ones),
  and Fib (30) = 832,040 fits `Result` (0 .. 1,000,000) while Fib (31) does not. Lengths 30 .. 32 used to be
  allowed and silently saturated at 1,000,000.
- Postcondition (functional): `Count` equals the ghost specification `Ways` (the recursive definition by the
  last code), whose own postcondition bounds it by `Fib (K + 1)`; proved at Silver level 2 with cvc5
  (30 checks).
- `make test` runs the hand cases and the own recursive decoding reference (tests/SOURCES.txt); `make prove`
  runs the proof.
