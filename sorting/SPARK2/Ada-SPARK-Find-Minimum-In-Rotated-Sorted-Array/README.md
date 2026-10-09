# Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array

Find the minimum of a rotated sorted array, in SPARK. `Data` holds 32 values in 0 .. 100. It is a strictly increasing array that has been turned around a pivot, so its tail now comes first, for example `4 5 6 7 0 1 2`. The precondition `Is_Rotated_Sorted` says this: for some pivot `P`, `Rotated_At (Data, P)` holds. Every neighbour pair increases except the one across `P - 1` / `P`, and when `P > 1` the last value is below the first.

`Find_Minimum (Data)` binary-searches for the pivot. It compares the middle value with the last value of the remaining range:
- If the middle value is larger, the descent lies after the middle.
- Otherwise the range from the middle to the end increases, so the pivot is not after the middle.

It returns the position of the minimum and the number of probes (at most 5 = log2 32). `Minimum (Data)` returns the value there.

The postconditions are proved:
- `Find_Minimum`: the value at `Position` is at most every `Data (I)`.
- `Minimum`: the result is at most every element and is one of them.

The proof works like this:
- A ghost `Pivot_Of` finds the pivot by a linear search, used only in the proof.
- `Lemma_Chain` shows that values increase inside each of the two parts.
- `Lemma_Step` shows that the comparison sends the search towards the pivot.
- The loop invariants keep the pivot inside `Lo .. Hi` and bound the width by 32 / 2 ** probes.
- `Lemma_Minimum` shows that the pivot holds the minimum.

The predicates use a single quantifier each. The cvc5 run that gnatprove makes cannot instantiate nested quantifiers in hypotheses, so the facts that need several steps are proved by induction lemmas.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (50 checks).

`make test` runs `tests.adb` and the folder's own checks (see `tests/SOURCES.txt`).

The first version had no search and no precondition: it scanned all 32 values linearly, so it never used the rotated order.
