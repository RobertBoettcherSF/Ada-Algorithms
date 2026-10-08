# Ada-SPARK-Sort-Array-By-Parity-II

Sort Array By Parity II in SPARK for 8 values in 0 .. 9: odd values go to the odd positions 1, 3, 5, 7 and
even values to the even positions 2, 4, 6, 8 (1-based), each group in input order.

- The placement is only possible with exactly four even and four odd values, so the input type says so:
  `Parity_Balanced` is `Int_Array` with a predicate `Evens_Up_To (A, 8) = 4`. An unbalanced input is refused
  at the call (Assertion_Error under -gnata; a proof obligation for SPARK callers) instead of losing values.
- Postcondition: every position holds a value of its own parity; proved at Silver level 2 with cvc5
  (38 checks). That the output is a permutation of the input is checked by the tests, not proved.

```sh
make test    # original case + own parity/permutation and rejection checks (tests/SOURCES.txt)
make prove
```
