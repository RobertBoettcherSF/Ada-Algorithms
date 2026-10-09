# Ada-SPARK-Longest-Repeating-Character-Replacement

Longest window of a text that can be turned into a run of one character by replacing at most `K` characters. Sliding window with per-character counts, O(n). Any lower bound, length up to `Max_Length`.

Proved at mode all, level 2: no run-time errors (the window counts are tied to a ghost occurrence count, so no count goes negative), and the Post gives the bounds `min (length, K + 1) <= result <= length`. The ghost counts are proof-only (not executed at run time). Optimality is checked by `make test`: a brute-force reference over every window, on all texts over {A,B,C} up to length 8 for K = 0..3 and 5,000 seeded random texts (seed 20261009), at lower bounds 1 and 9.

- `make test` builds and runs the tests (exit status reports failure).
- `make prove` runs level-2 CVC5 proofs with warnings and checks treated as errors.
