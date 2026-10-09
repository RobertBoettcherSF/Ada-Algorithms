# Ada-SPARK-Letter-Combinations-Of-A-Phone-Number

Letter combinations of a phone number on the standard keypad (2 = abc, 3 = def, 4 = ghi, 5 = jkl, 6 = mno, 7 = pqrs, 8 = tuv, 9 = wxyz), in SPARK. `Count (Number)` is the number of letter strings a digit string spells: the product of the key sizes. `Combination (Number, K)` is the K-th of them (K from 0) in dictionary order. It decodes K in mixed radix, last digit first: the letter index is K mod (key size), then K becomes K / (key size).

**Range widened:** the first version was a case table of 3 ** N for N <= 12. It assumed three letters per digit and returned only a count. Numbers now have up to 15 digits. That limit comes from the arithmetic: a key has at most 4 letters, so a count is at most 4 ** 15 = 2 ** 30 <= `Natural'Last`, while sixteen 7s or 9s would spell 4 ** 16 = 2 ** 32 strings. The old answers are still tested as counts of numbers made of 2s. `Digit_String` is a subtype whose predicate allows only 1-based strings of at most 15 digits 2 .. 9.

The proved contracts are `Count = Suffix_Count (Number, 1)` and, for `K < Count`, that the result spells the number and has `Rank (Number, Result, 1) = K` (200 checks). Both ghost functions are recursive: `Suffix_Count (I)` is the key size at I times `Suffix_Count (I + 1)`; `Rank (I)` is the letter's index on its key times `Suffix_Count (I + 1)`, plus `Rank (I + 1)`. The overflow bound uses a ghost table of 4 ** N that the proof checks against the recurrence.

## Checks

```text
make test
make prove
```

`make prove` runs level-2 GNATprove with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
