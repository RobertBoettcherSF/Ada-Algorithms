# Ada-SPARK-Tim-Sort-Stub

The insertion-sort kernel of Timsort (the step Timsort runs inside each min-run), in Ada 2022 with `SPARK_Mode => On`.

`Sort` takes any `Value_Array` (any `Positive` index range, length $n \le 10\,000$ = `Max_Len`) and returns an array with the same bounds that is sorted: $r_i \le r_j$ for all $i \le j$. Sortedness is a proved postcondition (Silver, `--level=2`); that the result is a permutation of the input is checked by the tests, not proved. Worst case $O(n^2)$ comparisons.

Earlier this folder sorted exactly 8 values in `-100 .. 100`, with no contract beyond absence of run-time errors.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` uses the default level-2 provers; cvc5 alone does not discharge the nested-quantifier invariants.
