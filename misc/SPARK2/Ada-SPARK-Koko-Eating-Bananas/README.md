# Ada-SPARK-Koko-Eating-Bananas

Koko eating bananas, in SPARK. There are 8 piles of 1 .. 100 bananas. At speed `S`, Koko eats up to `S` bananas from one pile per hour, so pile `P` takes ceil (`P` / `S`) hours (`Pile_Hours`). `Hours_Needed (Piles, S)` is the total over all piles, written as a recursive expression function.

`Minimum_Speed (Piles, Hours)` returns the slowest speed in 1 .. 100 that finishes within `Hours`, and the number of speeds it tried (`Probes`). Each try costs one pass over the piles. `Hours` is at least 8, one hour per pile, so speed 100 always finishes.

It is a binary search over the speeds. The postcondition is proved: the returned speed finishes in time, and every slower speed needs more than `Hours`. The proof uses three lemmas:
- `Lemma_Pile`: a faster speed never takes more hours for one pile (ceiling monotonicity);
- `Lemma_Monotone`: so it never takes more hours in total;
- `Lemma_Fastest`: speed 100 takes exactly 8 hours.

The loop keeps two facts: speed `Hi` finishes in time, and speed `Lo - 1` does not.

Cost: O(N log 100). `Probe_Count` is 0 .. 7 = ceil (log2 100), so the bound on speeds tried is proved: a ghost table bounds `Hi - Lo` by 99 halved once per try. `tests.adb` and the own checks also assert at most floor (log2 100) + 2 tries.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (68 checks).

`make test` runs `tests.adb` and the folder's own checks: 215,601 checks against a no-division simulation (see `tests/SOURCES.txt`).

The first version tried every speed from 1 upward (up to 100 passes over the piles), with no contract. Its README said n <= 32, but there are 8 piles. Commit 2e45ca2f added a try counter and a test asserting the log bound. That test fails on the old scan (11 tries when the answer is 11).
