# Ada-SPARK-Clone-Graph

Bounded graph cloning in SPARK (`SPARK_Mode => On`). The graph is a pool of 16 nodes. Each node has a label and 4 neighbour slots, where 0 marks an empty slot; repeats and self-loops are allowed.

`Clone (G, Start)` copies every node reachable from `Start` into a new graph with fresh ids. It works breadth-first, numbering the copies 1 .. `Size` in the order they are discovered, so `Start` becomes copy 1. Each copy keeps its node's label and, slot by slot, gets the copy of the neighbour or an empty slot. The result also returns `Map` (node -> copy id, 0 if the node was not copied) and `Orig` (copy id -> node).

The postcondition `Is_Clone` is proved:

* `Map` and `Orig` are inverse bijections between the copied nodes and 1 .. `Size`;
* copies carry the labels and the copies of the neighbours, so the copied set is closed under neighbours;
* copy nodes after `Size` are empty;
* every copied node other than `Start` is a neighbour of a node with a smaller copy id, so only reachable nodes are copied.

Ghost discovery records (`Parent`, `Via`) and a ghost count of the copied nodes, which bounds `Size`, carry the proof.

- `make test` builds and runs `tests.adb` and the own checks in `own_checks.adb` (see `tests/SOURCES.txt`).
- `make prove` runs Level 2 CVC5 proof with warnings and checks treated as errors (158 checks).

The first version used a 16 x 16 Boolean adjacency matrix, and `Clone` was `return G`. A value copy already does that, so the folder had no cloning algorithm in it.
