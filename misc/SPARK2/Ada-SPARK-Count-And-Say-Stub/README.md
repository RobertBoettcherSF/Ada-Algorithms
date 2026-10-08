# Ada-SPARK-Count-And-Say-Stub

Count-and-say sequence (LeetCode 38): term 1 is `1`; term $k+1$ reads term $k$ aloud (`1211` → one 1, one 2, two 1s → `111221`).

`Describe` computes any term whose text fits in `Max_Text` = 10 000 characters (terms 1 to 33; term 33 has 9 898 characters) and reports `Ok = False` otherwise. Proved (Silver, `--level=2`): no run-time errors, and the postcondition that the output holds only the digits `1`..`9` and that term 1 is `1`. The tests check terms against OEIS A005150 and the lengths of terms 1 to 20 against OEIS A005341.

Earlier this folder returned the first five terms from a table.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
