# Babylonian-Sqrt

Integer square root by the Babylonian (Newton) method, in SPARK. `Sqrt (N)` returns, for `N` in 0 .. 10,000, the largest `R` with `R * R <= N`. It also returns the number of refinement steps (`Steps`), one division each.

It starts at `X = 100`, which is above every root. Each step computes `Y = (X + N / X) / 2`. If `Y < X`, it continues with `Y`; otherwise it stops and returns `X`. It also stops at `X = 0`.

The postcondition `R * R <= N < (R + 1) * (R + 1)` is proved. The loop keeps `N < (X + 1) ** 2`, which `Lemma_Step` shows each step preserves:
- 2 (Y + 1) >= X + Q + 1, with Q = N / X;
- (X + Q + 1) ** 2 >= 4 X (Q + 1), because (X - Q - 1) ** 2 >= 0 (AM-GM);
- 4 X (Q + 1) > 4 N, because N < (Q + 1) X.

The lemma also shows that `Y < X` whenever `X * X > N`. So when the iteration stops with `Y >= X`, `X * X <= N`, and `X` is the root.

Cost: the proof only shows that `X` falls on every step but the last (at most 101 steps; `Step_Count` is 0 .. 101). The real cost is logarithmic: while `X` is far above the root, the step about halves it, and near the root it converges quadratically. `tests.adb` and the own checks assert at most floor (log2 101) + 2 = 8 steps for every input, and 8 is the measured worst case (`N` = 3).

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (86 checks).

The first version did no Babylonian step at all. It squared every candidate 0 .. 100 and kept the last one that fit (101 steps for every input), and it had no contract and no `prove` target. Commit f3a7b100 added a step counter and a test asserting the log bound. That test fails on the old loop.
