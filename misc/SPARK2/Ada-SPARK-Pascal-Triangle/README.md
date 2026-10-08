# Ada-SPARK-Pascal-Triangle

Pascal triangle row totals: `Row_Total (R)` is the sum of row R, computed by doubling (each row sums to
twice the row above). `Row_Index` is 0 .. 30 so that every total, 2**R, fits `Result` (at most 2**31 - 1);
rows 31 and 32 used to be allowed and silently saturated at 2**31 - 1.

- Postcondition: `Row_Total (R) = 2 ** R`; proved at Silver level 2 with the deterministic step budget
  (`make prove`: `--timeout=0 --steps=1000000`; cvc5 alone cannot bound the power).
- `make test` checks every allowed row against an own triangle built by additions (tests/SOURCES.txt).
