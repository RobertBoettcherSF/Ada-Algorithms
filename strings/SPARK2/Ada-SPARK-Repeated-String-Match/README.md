# Ada-SPARK-Repeated-String-Match

Repeated String Match in SPARK, strings of 1 .. 32 characters: `Repeat_Count` gives the fewest copies of
`Source (1 .. Source_Length)` whose concatenation contains `Target (1 .. Target_Length)` as a substring,
or 0 when no number of copies does (the usual statement says -1; here `Repeat_Type` is 0 .. 32).

- Every occurrence starts at some offset `S < Source_Length` inside a copy and then needs
  `ceiling ((S + Target_Length) / Source_Length)` copies, which grows with `S`; the first matching offset wins.
  No concatenation buffer is built, so long targets are not cut off.
- Lengths are `Positive_Length` (1 .. 32): empty strings are excluded by the type.
- Postcondition (functional, in terms of `Matches_At` and `Needed`): 0 exactly when no offset matches,
  otherwise `Needed` of the first matching offset. Proved at Silver level 2 with cvc5.
- `make test` runs the tests (hand cases + 20,000 random cases against an own brute force, see
  `tests/SOURCES.txt`); `make prove` runs the proof.
