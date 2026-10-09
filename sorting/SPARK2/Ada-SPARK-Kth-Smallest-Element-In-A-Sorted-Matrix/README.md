# Ada-SPARK-Kth-Smallest-Element-In-A-Sorted-Matrix

The K-th smallest entry of a sorted square block, in SPARK. A `Square` holds `N` (1 .. 8) and an 8 x 8 `Matrix` of values in 0 .. 1000; only the block `M (1 .. N, 1 .. N)` counts. In `Sorted_Square` (the subtype predicate) every entry of the block is <= its right neighbour and <= the entry below it. Rows need not continue one another. The predicate is stated over the row-major cells `Cell (M, K)` with one quantifier.

`Kth (S, K)`, for K in 1 .. N * N, returns the K-th smallest entry of the block (counting repeats), the number of counts it made (`Tries`) and the number of comparisons of an entry with a value (`Probes`).

It is a binary search on the value. `Count_Le (S, X)` counts the entries <= X by a staircase walk: start at the right end of row 1, move left while the entry is > X, and carry the column down to the next row (its boundary is never further right, because columns rise). The search keeps Count (Lo - 1) < K <= Count (Hi), starting from Lo = 0 and Hi = 1000.

The postcondition is proved: fewer than K entries are below the result and at least K are <= it, which is the definition of the K-th smallest. `Count` is defined by the recursive ghost functions `Row_Count` and `Total`. `Count_Le` is proved equal to it: `Lemma_Row_Count` shows that a row whose entries up to C are <= X and whose rest are > X has exactly C entries <= X, and `Lemma_Down` carries the boundary to the next row. `Lemma_None` and `Lemma_All` give the counts at Lo - 1 = -1 (0) and at Hi = 1000 (N * N).

Cost: O(N log R) for the value range R = 1001. A ghost table bounds Hi - Lo by 1000 halved per count, so `Tries` <= 10 is proved; each count makes at most 2 * N comparisons (each one either moves left or ends a row), so `Probes <= 2 * N * Tries` is proved in the postcondition. `tests.adb` asserts at most (floor (log2 1001) + 1) * 2 * N comparisons.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (144 checks), on `proof.gpr` (the package only).

`make test` runs `tests.adb`: the original 4 x 4 example, 10 (I + J) (equal values along anti-diagonals) and 3 I + 5 J (rows overlap) for every N and every K, against an insertion sort of the block.

The first version flattened the block and selection-sorted it up to position K (O(N ** 4) comparisons for K = N * N), with no contract and no sortedness requirement; its one test checked K = 8 of the 4 x 4 example. The failing test that came first added a comparison counter and the bound above. It fails on the old code (84 comparisons for the 4 x 4 example at K = 7, where the bound is 80).
