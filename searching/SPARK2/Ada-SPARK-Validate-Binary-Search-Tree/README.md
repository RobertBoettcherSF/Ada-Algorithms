# Ada-SPARK-Validate-Binary-Search-Tree

PLACEHOLDER: toy-size validator with a 256-step limit and a stack-full guard that can skip nodes; see H125

Validation of bounded array-backed binary search trees.

Bounded to 15 addressable nodes with fixed-size array-backed storage and `SPARK_Mode (On)`.

```sh
make test
make prove
```

## Notes (V&V sweep, 2026-10-09)

`Is_Valid_BST` walks the links from `Root` depth-first with a stack of at
most 15 entries. Each node is marked when it is pushed; a node reached a
second time means the links are not a tree (a cycle or a shared child) and
the answer is False. The walk runs until the stack is empty, so every
reachable node is checked: the proof shows the stack never overflows and
the loop ends (loop variant `2 * (15 - marked nodes) + stack size`, with a
ghost counting lemma). The earlier version had a 256-step limit and a
stack-full guard that would have skipped nodes and returned True; no input
reached them (two paths to one node always give it disjoint bounds), but
nothing proved that. A link to a node that was never set checks that
node's stored value (0). Bounds are a toy size: 15 nodes, values
-100 .. 100.
