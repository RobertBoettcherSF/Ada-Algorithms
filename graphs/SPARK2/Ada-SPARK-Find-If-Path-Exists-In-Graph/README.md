# Ada-SPARK-Find-If-Path-Exists-In-Graph

Bounded breadth-first path search for graphs with at most 16 vertices.

The implementation is bounded and uses `SPARK_Mode => On`.

- `make test` builds and runs checks.
- `make prove` runs Level 2 proof with CVC5, warnings, and checks as errors.

Edges are directed: `Edges (A, B)` is an edge from `A` to `B`. For the
undirected version of the exercise set both `Edges (A, B)` and
`Edges (B, A)`. A vertex always reaches itself (`Start = Goal` gives True).
