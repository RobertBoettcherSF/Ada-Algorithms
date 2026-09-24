# Ada-SPARK-Is-Graph-Bipartite

Bounded bipartite check for graphs with at most 16 vertices.

The implementation is deliberately bounded and uses `SPARK_Mode => On`.

- `make test` builds and runs the checks.
- `make prove` runs Level 2 CVC5 proof with warnings and checks treated as errors.
