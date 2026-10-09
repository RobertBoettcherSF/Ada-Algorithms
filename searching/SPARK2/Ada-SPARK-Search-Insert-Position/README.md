# Ada-SPARK-Search-Insert-Position

Search insert position, in SPARK. `Data` is a sorted array of 32 values in 0 .. 100. Sortedness is the subtype predicate of `Sorted_Array`, and duplicates are allowed. `Position (Data, Target)` returns where `Target` is, or where it would be inserted: the first position whose value is >= `Target`, or 33 if there is none.

It is a half-open binary search over the 33 insertion points. It reads the middle element and keeps the half that still holds the answer. It returns the position and the number of elements read (`Probes`).

The postcondition is proved: every element before `Position` is < `Target`, and every element from `Position` on is >= `Target`. The loop keeps two facts:
- the element just before `Lo` is < `Target`;
- the element at `Hi` is >= `Target`.

`Lemma_Split` then extends these two neighbour facts to the whole array, using the predicate and the chain lemma `Lemma_Chain`.

Cost: O(log N). `Probe_Count` is 0 .. 6 = floor (log2 33) + 1, so the bound on reads is proved: a ghost table bounds `Hi - Lo` by 32 / 2 ** probes. `tests.adb` and the own checks also assert at most floor (log2 N) + 2 reads. Duplicates do not change the cost, because the search never needs to tell equal values apart.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (37 checks).

`make test` runs `tests.adb` and the folder's own checks: 433,069 checks against a linear scan (see `tests/SOURCES.txt`).

The first version scanned the whole array linearly, with no contract and no sortedness requirement. Commit bc41336a added the read counter to it and a test asserting the log bound; that test fails on the old scan (32 reads for the last element).
