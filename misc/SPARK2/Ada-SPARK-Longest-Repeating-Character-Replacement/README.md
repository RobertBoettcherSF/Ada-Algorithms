# Ada-SPARK-Longest-Repeating-Character-Replacement

Longest window of a text that can be turned into a run of one character by replacing at most `K` characters. Sliding window with per-character counts, O(n). Any lower bound, length up to `Max_Length`.

Proved at mode all, level 2 (195 checks): no run-time errors and the functional Post: for a non-empty text the result `R` is in `1 .. length`, some window of length `R` is fixable (some character of the window fills all but at most `K` places), and, unless `R` is the whole length, no window of length `R + 1` is fixable. Fixability is downward closed (dropping an end character lowers the length by 1 and any count by at most 1, `Lemma_Down`), so no longer window is fixable either. The proof keeps a ghost witness window that reaches the (possibly stale) maximum count `Most`, and shows every current count is `<= Most`, so a slid window of length best + 1 is never fixable.

The loop invariants, assertions and the body lemmas' contracts are proof-only (not evaluated at run time: they would cost O(n * n * 256) per call); the functional Post in the spec is checked on every call under `-gnata`. `make test` also compares with a brute-force reference over every window, on all texts over {A,B,C} up to length 8 for K = 0..3 and 5,000 seeded random texts (seed 20261009), at lower bounds 1 and 9.

- `make test` builds and runs the tests (exit status reports failure).
- `make prove` runs level-2 CVC5 proofs with warnings and checks treated as errors.
