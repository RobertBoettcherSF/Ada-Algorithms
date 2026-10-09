# Ada-SPARK-Climbing-Stairs

How many ways are there to climb N stairs taking one or two steps at a
time, and which climb is the K-th in dictionary order?

* `Count (N)`: the dynamic program over the first step (a climb of N
  stairs starts with a single step, leaving N - 1, or a double step,
  leaving N - 2), stepping the pair (Ways (J), Ways (J - 1)) upward.
* `Climb (N, K)`: the K-th climb (from 0, single step ordered before
  double step), built front to back: with R stairs left, if K is below
  Ways (R - 1) the next step is single, otherwise it is double and K drops
  by Ways (R - 1).

Range: `N in 0 .. 45`. The limit comes from overflow: Ways (45) =
1_836_311_903 fits Natural, Ways (46) = 2_971_215_073 does not, and every
intermediate value is at most the result. (The old version was a case
table for N <= 10.)

Proof (`make prove`, level 2, cvc5, 318 checks): the specification is the
ghost function `Ways`, read from a ghost table the body builds once by the
recurrence; its postcondition gives the recurrence, Ways (0) = Ways (1) = 1,
the two limit values and monotonicity. `Count (N) = Ways (N)`; the result
of `Climb` has steps 1 or 2 summing to N and dictionary rank K, where the
rank adds Ways (R - 1) for each double step taken with R stairs left. That
the rank lists every climb exactly once in dictionary order is the
standard first-step argument; the own checks confirm it by enumeration
for N <= 15.

Tests: `make test` (hand-derived values, see tests/SOURCES.txt) and
`own_checks.adb` (own enumerator, own closed count by binomials, seeded
random ranks; seed printed, AA_SEED overrides).
