# Ada-SPARK-Squares-Of-A-Sorted-Array

Squares of a Sorted Array in SPARK, 32 values in -32 .. 32: `Squares (A)` returns the squares of the sorted
input in non-decreasing order (two pointers from both ends, the larger magnitude placed last first).
(An earlier version only squared each element, unsorted.)

- The input type `Sorted_Array` states that the input is sorted (predicate); an unsorted input is refused
  at the call (Assertion_Error under -gnata).
- Postcondition: the result is sorted and holds exactly the squares of A, each value as often as it
  is the square of an element of A (`Count_Of (Result, 1, 32, V) = Sq_Count (A, 1, 32, V)` for every
  `V`); proved at level 2 (`make prove`, 102 checks). The proof tracks that the placed squares plus the
  squares of the unplaced window `A (L .. R)` always count the same as the squares of A. The body's
  invariants and lemma contracts are proof-only (not executed); the Post is checked on every call.
  The tests also compare with an own square + insertion-sort reference.

`make test` builds and runs the checks (tests/SOURCES.txt); `make prove` runs the level-2 proof.
