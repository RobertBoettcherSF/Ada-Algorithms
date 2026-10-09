# Ada-SPARK-Unique-Binary-Search-Trees

Number of structurally different binary search trees on the keys 1 .. N (the N-th Catalan number), for N in 0 .. 19 (Catalan (19) = 1,767,263,190 is the largest that fits Integer; the result type is Long_Long_Integer).

Algorithm: dynamic programming, T (0) = 1 and T (M) = sum over the root K in 1 .. M of T (K - 1) * T (M - K). No closed-form multiplication (that could overflow before its division).

Proof (SPARK Silver, `make prove`): no run-time error, using the ghost bound T (M) <= M! (lemma A! * B! <= (A + B)!), which keeps every partial sum inside Long_Long_Integer; Post: Result <= N!.

Tests: `tests.adb` (original: N = 0, 3, 16) and `own_checks.adb` (every N in 0 .. 19 against the closed form binomial (2N, N) / (N + 1), and N <= 8 against enumerating the BST shapes of every insertion order).
