# Ada-SPARK-Unique-BSTs-Stub

Number of structurally different binary search trees on the keys 1 .. N (the N-th Catalan number), computed by the dynamic-programming sum T(M) = sum over roots K of T(K-1) * T(M-K). N is bounded by its subtype to 0 .. 19 (T(19) = 1,767,263,190; T(20) no longer fits in Integer).

Proved at mode all, level 2 with cvc5, no Assume: every product and partial sum stays inside Long_Long_Integer via the bound T(M) <= M! (ghost factorial and the lemma A! * B! <= (A + B)!), which is also the Post. `make test` checks every N against the closed form binomial(2N, N) / (N + 1), N = 0 .. 8 against an independent enumeration (build the BST of every insertion order and count distinct shapes), and the known value at 19.

## Verification

```text
make test
make prove
```
