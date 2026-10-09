# Ada-SPARK-Exchange-Sort

A small bounded Ada/SPARK exchange sort. `Input_Array` has eight values in `0 .. 31`.

## Algorithm
For each position `I` in `1 .. 7`, compare `A (I)` with every later `A (J)` and exchange the two when `A (I) > A (J)`. After position `I` is done it holds the smallest value of `A (I .. 8)`. This always makes 28 comparisons.
Reference: https://en.wikipedia.org/wiki/Sorting_algorithm#Exchange_sort

## Contract
`Post => Is_Sorted (Sort'Result) and then Is_Perm (Sort'Result, Input)`.
`Is_Perm` compares occurrence counts (`Occ`) for every value of `Value` (32 values), so it is also checked at run time: the test build uses `-gnata`. The tests check that the predicates reject unsorted arrays and non-permutations. An earlier Post only bounded the elements, so a body returning `Input` proved it (vacuity scan, tools/vv/contract_scan.csv).

## Proof
`make prove`: level 2, CVC5, proof warnings on. Result: `Success: all checks proved (70 checks).` The same 70 checks prove in silver mode with the repository settings (tools/vv/prove_settings.txt). The permutation proof uses ghost lemmas `Lemma_Occ_Frame`, `Lemma_Occ_Set` and `Lemma_Swap` (count of a value after one slot changes, then after two). There is no `pragma Assume` and no `Annotate`.

## Tests
`make test` runs `tests.adb` (fixed cases plus the contract predicates) and the own checks: all 256 zero/one arrays, edge shapes, and 3,000 seeded random arrays, compared with an own insertion sort (tests/SOURCES.txt).
