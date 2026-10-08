# Ada-SPARK-Squares-Of-A-Sorted-Array

Squares of a Sorted Array in SPARK, 32 values in -32 .. 32: `Squares (A)` returns the squares of the sorted
input in non-decreasing order (two pointers from both ends, the larger magnitude placed last first).
(An earlier version only squared each element, unsorted.)

- The input type `Sorted_Array` states that the input is sorted (predicate); an unsorted input is refused
  at the call (Assertion_Error under -gnata).
- Postcondition: the result is sorted; proved at Silver level 2 with the default level-2 provers (31 checks;
  cvc5 alone gives up on one invariant). That the result holds exactly the squares of the input is checked
  by the tests (own square + insertion-sort reference), not proved.

`make test` builds and runs the checks (tests/SOURCES.txt); `make prove` runs the level-2 proof.
