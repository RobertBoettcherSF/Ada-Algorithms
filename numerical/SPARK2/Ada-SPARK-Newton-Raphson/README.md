# Ada-SPARK-Newton-Raphson

Integer square root by Newton-Raphson in SPARK: `Sqrt (N)` for `N` in 1 .. 10_000 returns the largest
`R` with `R * R <= N` (type `Root`, 1 .. 100).

- Eight integer Newton steps `X := (X + N / X) / 2` from `X = 100`, then a short correction (step down
  while `X * X > N`, up while `(X + 1) ** 2 <= N`): integer Newton alone ends one too high for
  `N = k ** 2 - 1`, where it alternates between `k - 1` and `k`.
- Postcondition: `R * R <= N < (R + 1) * (R + 1)`; proved at Silver level 2 with cvc5.
- `make test` builds and runs the tests (property check over all 10,000 inputs, see `tests/SOURCES.txt`).
- `make prove` runs level-2 CVC5 proofs with warnings and checks treated as errors.
