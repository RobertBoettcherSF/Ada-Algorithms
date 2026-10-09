# Ada-SPARK-Permutations-II

Distinct permutations of a list that may repeat items, in dictionary order, in SPARK. An `Arrangement` never changes its `Items`. It shows them through an index permutation `Order` (position K shows `Items (Order (K))`) kept together with its inverse `Place`, and the predicate keeps the two inverse to each other. So every arrangement shows exactly the items of the list, each as often as in the list, by construction. `Next_Permutation` uses non-strict comparisons: the pivot is the last position whose value is smaller than the next one, and it is swapped with the rightmost strictly larger value. Equal items are therefore never exchanged, and no arrangement repeats. From the last arrangement (values never increasing) it reverses everything to the sorted one and sets `Found` to False. `Count_Distinct (Items)` = N! / (m1! m2! ..), where m1, m2, .. are how often each value occurs.

**Range widened:** the first version was a count table for N <= 12 with a flag for "one repeated pair". `Count_Distinct` keeps N <= 12 because it goes through N!, and 12! = 479_001_600 is the last factorial that fits `Natural`. `Next_Permutation` takes any length up to `Positive'Last - 1`.

The proved contracts (205 checks), with termination of every while loop by a loop variant:
- the items never change;
- `Found` is False exactly when the old values never increase;
- with `Found`, the values go strictly up in dictionary order; without it, the result is sorted;
- `Count_Distinct = Fact (N) / Copies (Items, N)`, where the ghost `Copies` multiplies, for each position, how many copies of its value have appeared so far (the product of the m!).

That the division is exact and that each step gives the *next* arrangement is checked by the tests: full enumeration against an own generator, and an own N! / (m1! m2! ..).

## Checks

```text
make test
make prove
```

`make prove` runs level-2 GNATprove with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
