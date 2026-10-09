# Ada-SPARK-Search-A-2D-Matrix-II

Search a matrix whose rows and columns are sorted, in SPARK. `Grid` is 8 x 8 with values in 0 .. 100. Every entry is <= its right neighbour and <= the entry below it; the rows need not continue one another (row 1 may end above where row 2 starts). That is the subtype predicate of `Staircase_Matrix`, stated over `Cell (M, K)`, the K-th cell in row-major order: the right neighbour of cell K is K + 1 and the entry below it is K + 8.

`Contains (Grid, Target)` returns whether some cell equals `Target`, and the number of comparisons with cells it made (`Probes`; a three-way comparison counts once).

It walks a staircase from the top-right corner. If the entry equals `Target`, it is found. If it is larger, so is every entry below it in that column, and the column is dropped. If it is smaller, so is every entry left of it in that row, and the row is dropped.

The postcondition is proved: `Found` is true exactly when some cell equals `Target`. `Position_Of (R, C)` has a proved postcondition that it is the cell index of `Grid (R, C)`, so "some cell" is the same as "some entry". The loop keeps one fact: no cell in a dropped row or column equals `Target`. `Lemma_Drop_Column` and `Lemma_Drop_Row` extend one comparison to the whole column or row, through `Lemma_Column` and `Lemma_Row` (the predicate chained along a column or row).

Cost: O(Rows + Cols). Each comparison drops a row or a column or ends the search, so `Probes + (Rows + 1 - R) + C = Rows + Cols` is a loop invariant and `Probe_Count` 0 .. Rows + Cols - 1 = 15 is proved. `tests.adb` asserts the bound and that it is reached (target 57, the bottom-left corner of 1 .. 64).

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (73 checks), on `proof.gpr` (the package only).

`make test` runs `tests.adb`: three row- and column-sorted matrices (1 .. 64 row by row; 4 R + 3 C, whose rows overlap; R + C, with equal values along anti-diagonals), every target 0 .. 100 against a scan of every entry.

The first version scanned every cell and kept going after a hit (64 comparisons always), with no contract and no sortedness requirement; its test used `pragma Assert`. The failing test that came first added a comparison counter and asserted the bound Rows + Cols - 1. That test fails on the old scan.
