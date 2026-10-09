# Ada-SPARK-Topological-Sort-Lite

Topological sort of a directed graph on vertices 1 .. N (adjacency matrix, N up to 200): `Topo_Sort (Edges, N, Order, Ok, Left)` repeatedly takes the smallest remaining vertex with no incoming edge from the remaining ones (O(N^3) on the matrix). Either `Ok` and `Order (1 .. N)` is a topological order, or not `Ok` and `Left` is a cycle certificate: a non-empty set in which every vertex has an incoming edge from the set (so no topological order exists: the first vertex of the set in any order would have a predecessor after it). `Is_Valid_Order` now checks strictly: Order (1 .. N) is a permutation of 1 .. N (it used to accept repeated vertices) and no edge points backward or is a self-loop. ("Lite" is the old folder name.)

Proof (SPARK, `make prove`, level 2, cvc5 + z3, 120 checks): no run-time error and the full Posts: `Is_Valid_Order` equals the spec function `Valid_Order`; `Topo_Sort` gives a `Valid_Order` or a `Cycle_Certificate`. Ghost counting lemmas show a vertex is left whenever fewer than N have been taken. cvc5 alone does not close some loop-invariant frames at this level; z3 does (the canonical reproof uses cvc5, z3, alt-ergo).

Tests: `tests.adb` (original) and `own_checks.adb` (Ok iff some permutation is valid: all graphs on 1 .. 3 vertices with self-loops, 2,000 random graphs on 4 .. 6; a DFS cycle search for 300 random graphs up to 200 vertices; the order checked by an own position table; `Is_Valid_Order` against that check on random orders; seed 20261009).

```sh
make test
make prove
```
