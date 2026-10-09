# Lemke-Howson Algorithm in Ada/SPARK

## Overview
Finds a Nash equilibrium of a two-player (bimatrix) game with integer
payoffs, up to 5 x 5, by the Lemke-Howson algorithm: complementary
pivoting on the best-response polytopes P = {x >= 0 : B'^T x <= 1} and
Q = {y >= 0 : A' y <= 1} (A', B' are the payoffs shifted so the smallest
entry is 1, which does not change best responses). Labels 1 .. M are
player 1's strategies, M + 1 .. M + N player 2's; `Initial_Drop` picks
the label dropped first, and different labels can reach different
equilibria.

The arithmetic is exact. The tableaux hold `Big_Integer` entries and are
updated by integer (fraction-free) pivoting: each new entry is
(pivot * entry - column entry * pivot-row entry) / previous pivot, an
exact division, so nothing can overflow whatever the `Integer` payoffs
(the pre-division products of a 32-bit game need far more than 64 bits).
Degenerate games (ties, several best responses) are handled by the
lexicographic ratio test (ties broken by the rows of the inverse basis,
the slack columns), which never revisits a basis, so pivoting cannot
cycle.

```ada
function Find_Equilibrium (A, B : Payoff_Matrix; Initial_Drop : Label_Type := 1)
  return Exact_Equilibrium;
--  Result: X (I) / Dx and Y (J) / Dy, Status (Found, Step_Cap_Reached,
--  No_Pivot_Row or Check_Failed) and Pivots.
```

## Contract
* `Post`: `(Status = Found) = Is_Nash (A, B, X, Dx, Y, Dy)` and
  `Pivots <= Path_Cap (M, N)` (= C (M + N, M) ** 2, the no-cycling bound): Status = Found is exactly the statement that
  both are probability vectors and every strategy played with positive
  probability is a best response (exact, in `Big_Integer`). A Found
  result is a proved certificate.
* This is a partial functional claim ("if Found then an equilibrium"): a
  body that never reports Found would satisfy it too. That Status is
  always Found (the path reaches an equilibrium within `Path_Cap (M, N)`
  pivots, at most 252 ** 2) is the Lemke-Howson theorem with the lexicographic
  rule; it is tested (every starting label, degenerate games included),
  not proved: tools/vv/handover.csv H096.
* Termination is by the loop bound, not a proved variant: the loop runs
  at most `Path_Cap (M, N)` = C (M + N, M) ** 2 pivots (each tableau has
  C (M + N, M) bases and the lexicographic rule never revisits a pair). Every other way out is reported in
  `Status`, never folded into a silent "not found": `Step_Cap_Reached`
  (Path_Cap pivots without reaching the end of the path),
  `No_Pivot_Row` (the entering column has no positive entry; impossible
  for these bounded polytopes) and `Check_Failed` (the path ended but the
  pair failed the exact check). The tests require Status = Found on every
  call.
* `Pre`: strategies are numbered from 1 (labels are built from the
  strategy numbers) and `Initial_Drop <= M + N`.

## Usage
* `make test`: build and run tests.adb (exit status 1 on failure).
* `make prove`: gnatprove level 2, cvc5, warnings and unproved checks as
  errors.
* `make clean`.

## Verification
* Proof (gnatprove 16.1.0): absence of run-time errors and the
  postcondition, 258 checks, all proved by `make prove` (level 2) on the
  current code. Level 4 and the silver-mode run with the repository's
  step limits have not been re-run on this version yet. No
  `pragma Assume` or `Annotate`.
* Tests (tests.adb): an own exact best-response check for every starting
  label, and the hand-worked equilibria where they are known; degenerate
  games where the old floating-point version returned a non-equilibrium;
  payoffs at `Integer'First` / `Integer'Last`; seeded random 3 x 3 and
  4 x 4 games and degenerate ones (payoffs 0 .. 1, or a repeated row and
  column), every starting label, Status = Found and pivots within
  C (M + N, M) ** 2.
* Own checks (`own_checks.adb`): against an independent support
  enumeration (Cramer's rule, Laplace determinants) on 300 seeded
  wide-range games, and the best-response check on every 2 x 2 game with
  payoffs 0 .. 2 and 1,500 seeded small-payoff games. Sources and
  numbers: tests/SOURCES.txt.

```
gnatmake -gnata -gnatwa -gnat2022 own_checks.adb && ./own_checks
```
