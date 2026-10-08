# Ada-SPARK-Jump-Game

Jump Game in SPARK: `A (I)` is the longest jump allowed from index `I`; `Can_Jump (A, N)` says whether
index `N` can be reached starting at index 1 (greedy furthest-reach scan, one pass).

- Arrays have 32 slots; `N` is an `Index` (1 .. 32), so no precondition is needed.
- Jump lengths are any `Natural`; reach arithmetic is done in `Long_Long_Integer`, so nothing saturates.
- Postcondition (functional): the result is True exactly when every index `K` in 2 .. N is reached from some
  earlier index `J` with `J + A (J) >= K` (`Covered`), which is the case exactly when `N` is reachable.
  Proved at Silver level 2 (default provers; cvc5 alone gives up on the nested quantifier).
- `make test` builds and runs the tests (hand cases + 20,000 random arrays against an own breadth-first
  reference, see `tests/SOURCES.txt`).
- `make prove` runs the level 2 proof.
