# Ada-SPARK-Restore-IP-Addresses

Restore IP addresses: `Restore (D, Len, List, Count)` lists every way to cut the digit string D (1 .. Len), Len up to 20, into 4 parts that are each 0 .. 255 without a leading zero. An address is given by its 4 part lengths (dots after A (1), A (1) + A (2), A (1) + A (2) + A (3)); the list is in lexicographic order of the lengths, at most 27 entries. Method: try the 27 choices of the first three lengths; the fourth is what is left. The original `Valid_Segment` / `Count_Valid_Segments` on a fixed 12-digit sequence are kept.

Proof (SPARK, `make prove`, cvc5 level 2, 108 checks): no run-time error and the full functional Post: every listed address is valid, the list is strictly increasing (so no repeats), and every valid address is listed (for each of the 27 choices C of the first three lengths, `First_Of / Second_Of / Third_Of` in the spec, a valid one is found by the ghost `Position`).

Tests: `tests.adb` (original) and `own_checks.adb` (brute force over all dot positions; 25525511135 -> 2, 0000 -> 1, 101023 -> 5, 255255255255 -> 1, 13 digits -> 0; every string of length 0 .. 7 over {0, 1, 2, 5, 6, 9}; 20,000 random strings of length 0 .. 20; seed 20261009).

## Verify

```sh
make test
make prove
```
