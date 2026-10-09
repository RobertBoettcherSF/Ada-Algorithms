# Ada-SPARK-Different-Ways-To-Add-Parentheses-Lite

In how many ways can an expression of N operands be fully parenthesized,
and what is the value of each way?

* `Number_Of_Ways (N)`: the split dynamic program. The last operator
  applied leaves K operands on its left and N - K on its right, so
  W (1) = 1 and W (N) = sum over K in 1 .. N - 1 of W (K) * W (N - K)
  (computed in Big_Integer, the result fits Natural).
* `All_Results (Values, Ops)`: the value of every parenthesization of
  `Values (1) Ops (1) Values (2) ... Values (N)` with `+`, `-` and `*`,
  ordered by the position of the last operator applied (left to right),
  then by the left part's results, then by the right part's results.
  Divide and conquer over the last operator; parts are recomputed rather
  than tabled (3 ** (N - 1) calls, 6_561 for N = 9).

Range: `Number_Of_Ways` takes N in 1 .. 20. The limit comes from
overflow: W (20) = 1_767_263_190 fits Natural, W (21) = 6_564_120_420
does not. `All_Results` takes 1 .. 9 operands in -99 .. 99. The limit
comes from overflow too: every value of a part of L operands is at most
99 ** L in absolute value (each operator at most multiplies the bounds
of its parts, and 99 ** P + 99 ** Q <= 99 ** (P + Q)), and
99 ** 9 = 913_517_247_483_640_899 < 2 ** 63 - 1 while 99 ** 10 does not
fit, so Long_Long_Integer holds every value of up to 9 operands (nine
factors 99 reach 99 ** 9) but not of 10. That gives at most W (9) =
1_430 results. (The old version was a case table of counts for N <= 8
and had no results.)

Proof (`make prove`, level 2, cvc5, 1_503 checks): the specification is
the ghost function `Ways`, a ghost table of values (an expression
function, so nothing runs at elaboration) that `Lemma_Facts` proves
satisfies the recurrence with W (1) = 1, which fixes every entry, plus
the limit values. `Number_Of_Ways (N) = Ways (N)`. `All_Results` returns
exactly Ways (N) values, each within the bound `Bound (N)` = 99 ** N
(a case table of values, checked by the own checks), with no overflow;
the bound of a part is carried by the element subtype of its result
array. That the values are those of the parenthesizations is not in
the contract; the own checks compare them with two own references. The
ghost lemmas called at run time cost O (L ** 2) Big_Integer operations
each (only the chain for the length in use).

Tests: `make test` (hand-derived values, see tests/SOURCES.txt) and
`own_checks.adb` (own shift-reduce enumerator, own ordered reference,
closed Catalan count, regenerated ghost tables, seeded random
expressions; seed printed, AA_SEED overrides).
