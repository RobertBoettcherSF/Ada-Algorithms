# Ada-SPARK-Subtree-Of-Another-Tree

A bounded structural subtree check with fixed-size stacks.

Bounded to 15 addressable nodes with fixed-size array-backed storage and `SPARK_Mode (On)`.

```sh
make test
make prove
```

## Notes (V&V sweep, 2026-10-09)

`Is_Subtree (T, Root, Pattern, Pattern_Root)` only considers nodes under
`Root`. Before 2026-10-09 every used node of `T` was a candidate, so a
matching node that is set but not linked from `Root` made the answer True
(test in `tests.adb`). `Same_At` still has a 256-step limit; links that are
not a tree (a cycle) are outside the problem.
