# Ada-SPARK-Permutations

Permutations in dictionary order, in SPARK. A `Perm` holds an arrangement `Order` (position K takes item `Order (K)`) together with its inverse `Place` (item V stands at position `Place (V)`). The type's predicate keeps the two inverse to each other, so `Order` always holds every number 1 .. N exactly once. `Next_Permutation` steps to the next permutation: it finds the pivot (the item just before the longest non-increasing tail) and the rightmost item larger than the pivot, swaps them, and reverses the tail. From the last permutation N, .., 1 it wraps around to `Identity (N)` and sets `Found` to False, so stepping from `Identity (N)` until `Found` is False visits all N! permutations. `Count (N)` is N!.

**Range widened:** the first version was only a case table of N! for N <= 12, with no permutations at all. `Count` keeps N <= 12 because the arithmetic stops there: 12! = 479_001_600 fits `Natural` and 13! = 6_227_020_800 does not. `Next_Permutation` does no counting, so its length is bounded only by `Positive'Last - 1` (the code reads index K + 1).

The proved contracts (113 checks):
- every step keeps a permutation (the predicate);
- `Next_Permutation` terminates: each of its three `while` loops has a `Loop_Variant` (I, J, Hi - Lo);
- `Found` is False exactly when the old arrangement never increases;
- a step with `Found` goes strictly up in dictionary order (ghost `Lex_Less`), and one without `Found` gives the identity;
- `Count = Fact (N)`, against a ghost recursion whose values a ghost table checks.

That each step is the *next* permutation is checked by the tests: full enumeration against an own generator, and rank + 1 under an own Lehmer-code rank. The inverse array is there because cvc5 does not prove the pairwise "all different" form of the predicate.

## Checks

```text
make test
make prove
```

`make prove` runs level-2 GNATprove with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
