# Ada-SPARK-Find-First-And-Last-Position

Find the first and last position of a value in a sorted array, in SPARK. `Data` is a sorted array of 32 values in 0 .. 100. Sortedness is the subtype predicate of `Sorted_Array`, and duplicates are allowed. `Locate (Data, Target)` returns the run of `Target`: its `First` and `Last` positions, or (0, 0) when `Target` is absent, plus the number of elements read (`Probes`).

It makes two half-open binary searches, both in `Boundary_Search`:
- one for the first element >= `Target`;
- one for the first element > `Target`.

If the two boundaries meet, `Target` is absent. Otherwise its run is `First` .. `Last`, where `First` is the first boundary and `Last` is one before the second.

The postcondition is proved:
- when absent: no element equals `Target`;
- otherwise: elements before `First` are < `Target`, those in `First` .. `Last` equal `Target`, and those after `Last` are > `Target`.

Each search keeps the neighbour facts at `Lo - 1` and `Hi`. `Lemma_Split` extends them to the whole array, using the predicate and `Lemma_Chain`.

Cost: O(log N), two searches. `Probe_Count` is 0 .. 12 = 2 * (floor (log2 33) + 1), so the bound on reads is proved: in each search a ghost table bounds `Hi - Lo` by 32 / 2 ** probes. `tests.adb` and the own checks also assert at most 2 * (floor (log2 N) + 2) reads. A run of many equal values costs no more, because neither search walks along the run.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (50 checks).

`make test` runs `tests.adb` and the folder's own checks: 433,069 checks against a linear scan (see `tests/SOURCES.txt`).

The first version scanned all 32 elements, with no sortedness requirement and no contract. Commit eccd9108 added a read counter to it and a test asserting the log bound; that test fails on the old scan (32 reads).
