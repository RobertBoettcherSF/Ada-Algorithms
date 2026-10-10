# Ada-SPARK-Integer-Break

Split an integer N >= 2 into at least two positive parts so that the
product of the parts is as large as possible. What is that product, and
which split gives it?

* `Maximum (N)`: the dynamic program over the first part. A split of M
  starts with a part K in 1 .. M - 1; the rest M - K is either kept whole
  or split again, so Best (M) = max over K of K * max (M - K, Best (M - K)).
* `Best_Split (N)`: a split with that product. It takes the smallest best
  first part, then keeps the rest whole when that is at least as good as
  splitting it, else splits the rest the same way. For example 10 gives
  2 + 2 + 3 + 3 = 36.

Range: N in 2 .. 58. The limit is overflow of the Positive result:
Best (58) = 4 * 3 ** 18 = 1_549_681_956 fits, Best (59) = 2 * 3 ** 19 =
2_324_522_934 does not. Every intermediate product is at most the result.
(The old version was a case table for N in 2 .. 10.)

Proof (`make prove`, level 2, cvc5, 852 checks): `Maximum (N)` equals the
ghost table `Best (N)`. The table is pinned down by `Row (M)`, proved for
every M by `Lemma_Row`: no first part K gives more than `Best (M)`
(`Cand (M, K) <= Best (M)`), and the ghost first part `Arg (M)` gives
exactly `Best (M)`. Together with `Best (1) = 0` this fixes every entry
from the smaller ones. `Best_Split (N)` has at least two parts, sums to N,
and its product is `Maximum (N)`. The ghost lemma `Lemma_Optimal` proves
that no split of N into at least two parts has a larger product, so
`Maximum` is the maximum. No overflow anywhere. The ghost `Sum_To` /
`Product_To` count parts from `P'First`, so a split may start at any
index (`Lemma_Optimal` needs only `P'Length >= 2`).

Tests: `make test` runs the hand-derived values (see tests/SOURCES.txt)
and then `own_checks.adb` (own exhaustive enumeration of every partition for N <= 58,
own closed form, the ghost tables regenerated, the `Best_Split` rule
rebuilt from the enumerated values, seeded random splits through
`Lemma_Optimal`, also at shifted origins; seed printed, AA_SEED overrides).
