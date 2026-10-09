# Ada-SPARK-Binary-Search-Lower-Bound

Binary search lower bound, in SPARK. `Input` is a sorted array of 32 values in -100 .. 100. Sortedness is the subtype predicate of `Input_Array`, and duplicates are allowed. `Find (Input, Target)` returns the first position whose value is >= `Target`, or 33 if there is none.

It is a half-open binary search over the 33 candidate positions. It reads the middle element and keeps the half that still holds the answer. It returns the position and the number of elements read (`Probes`).

The postcondition is proved: every element before `Position` is < `Target`, and every element from `Position` on is >= `Target`. The loop keeps two facts:
- the element just before `Lo` is < `Target`;
- the element at `Hi` is >= `Target`.

`Lemma_Split` then extends these two neighbour facts to the whole array, using the predicate and `Lemma_Chain`.

Cost: O(log N). `Probe_Count` is 0 .. 6 = floor (log2 33) + 1, so the bound on reads is proved: a ghost table bounds `Hi - Lo` by 32 / 2 ** probes. `tests.adb` and the own checks also assert at most floor (log2 N) + 2 reads. Duplicates do not change the cost.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (37 checks).

`make test` runs `tests.adb` and the folder's own checks: 900,069 checks against a linear scan (see `tests/SOURCES.txt`).

The first version was a fixed if-chain over 6 elements (`if Input (1) >= Target then 1 elsif Input (2) ...`): a linear first match with no sortedness requirement and no contract. Commit 39dd5aef wrote that chain as a loop over 32 elements, counted its reads, and added a test asserting the log bound; that test fails on the old chain. The 6 original test values are kept as a prefix of the test array.
