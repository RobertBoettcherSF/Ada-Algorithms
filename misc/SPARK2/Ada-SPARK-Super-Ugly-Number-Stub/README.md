# Ada-SPARK-Super-Ugly-Number-Stub

Super ugly numbers: `Nth_Super_Ugly_General (Factors, N, Value, Fits)` gives the N-th smallest positive integer that is a product of the given factors (1 is the empty product), for up to 100 factors in 2 .. 1000 (prime or not, repeats allowed) and N up to 10**5, by the multi-pointer merge (U (K) = smallest U (Idx (J)) * F (J); every pointer reaching it moves on, so equal products appear once). Values are reported up to Integer'Last; `Fits` is False exactly when the N-th value is larger. The original `Nth_Super_Ugly (N)` (factors 2, 7, 13, 19, N in 1 .. 12) now calls it. (The folder name keeps its old `-Stub` suffix.)

Proof (SPARK Silver, `make prove`, cvc5 level 2, 43 checks): no run-time error; Post: `Value = 1` when not `Fits`, and with factor 2 and N <= 31 the value fits and is at most 2 ** (N - 1) (which proves the original function's 1 .. 1,000,000 result). Not in the Post (partial claim, `tools/vv/contract_scan.csv`): that Value is the N-th product; `own_checks.adb` checks it.

Tests: `tests.adb` (original) and `own_checks.adb` (a divisibility-table reference for values <= 200,000 over 300 random factor lists incl. repeats and composites; a sorted depth-first product list for large N with 1, 4 and 10 prime factors; the first value above 2**31 - 1 must give Fits = False; the original fixed set for N = 1 .. 12; seed 20261009).

## Verification

```text
make test
make prove
```
