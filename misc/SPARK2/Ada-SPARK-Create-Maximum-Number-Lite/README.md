# Ada-SPARK-Create-Maximum-Number-Lite

Create Maximum Number (LeetCode 321): `Max_Number (A, M, B, N, K)` returns the largest K-digit sequence formed from A (1 .. M) and B (1 .. N), M, N up to 32, keeping the relative order of the digits taken from each. For every split K = LA + LB it takes the largest LA-digit subsequence of A and LB-digit subsequence of B (monotonic stack), merges them greedily (take from the sequence whose rest is lexicographically larger, a longer sequence beating its own prefix) and keeps the best. The original `Maximum_Digit` / `Maximum_Prefix` are kept. ("Lite" is the old folder name.)

Proof (SPARK Silver, `make prove`, cvc5 level 2, 48 checks): no run-time error (stack size, merge indices: the greedy comparison is proved to pick only from a sequence that still has digits). No functional Post: that the result is the maximum is checked by `own_checks.adb` only (`tools/vv/contract_scan.csv`, weak).

Tests: `tests.adb` (original) and `own_checks.adb` (brute force over all subsequence pairs and all interleavings; LeetCode 321 examples, exhaustive digit strings on {0, 1} with M, N <= 3 and every K, 3,000 random cases with M, N <= 5 and many ties, a full 32 + 32 -> 64 run; seed 20261009).

```sh
make test
make prove
```
