# Ada-SPARK-Ugly-Number-II

An ugly number is a positive number with no prime factor other than 2, 3
and 5, that is 2 ** a * 3 ** b * 5 ** c (1 is the first). What is the
N-th ugly number?

* `First_Ugly (N)`: the first N ugly numbers in increasing order, each
  with its exponents (a, b, c), by the three-pointer merge (the next one is
  the smallest of 2, 3 and 5 times the entries the three pointers are on).
* `Nth_Ugly (N)`: the value of the last entry of `First_Ugly (N)`.

Values are `Big_Integer`, so nothing overflows (in a 32-bit `Positive`
the 1_691st, 2_125_764_000, would be the last; the 1_692nd is 2 ** 31).
Range: N in 1 .. 2_000, a run-time limit with assertions enabled (the
tests and mutation runs use them): the contracts compare every entry with
the others, O (N ** 2) `Big_Integer` operations per call. One
`First_Ugly (2_000)` takes about 2.3 s on the sweep machine, 1_000 about
0.5 s and 3_000 about 4.1 s. (The old version was a lookup table.)

Proof (`make prove`, level 2, cvc5, 475 checks): every entry's value
is 2 ** a * 3 ** b * 5 ** c for its exponents (a record predicate; the
power function `Val3` sits in package `Ugly_Powers` with three lemmas,
so its nonlinear definition stays out of the other proofs); the list
starts at 1, increases, and holds 2, 3 and 5 times each entry whenever that
is not above the last entry; `Lemma_Complete` proves that such a list
holds every 2 ** a * 3 ** b * 5 ** c up to its last entry, so the K-th
entry is the K-th ugly number. Exponents are bounded by the index (the
K-th ugly number has a + b + c <= K - 1).

Tests: `make test` (hand-derived values, see tests/SOURCES.txt) and
`own_checks.adb` (own enumeration of 2 ** a * 3 ** b * 5 ** c, own
factorization of the exponents, `Lemma_Complete` run on every triple up
to the 300th ugly number; seed printed, AA_SEED overrides).

## Verification

```text
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
gnatmake -gnata -gnatwa -gnat2022 own_checks.adb && ./own_checks
```
