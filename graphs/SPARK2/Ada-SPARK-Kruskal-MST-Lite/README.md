# Ada-SPARK-Kruskal-MST-Lite

PLACEHOLDER: sums every edge cost; no edge selection or union-find, so no spanning tree; see tools/vv/hidden_stub.csv

Bounded Kruskal-style edge forest cost accumulator for at most 16 edges.

The implementation is bounded and uses `SPARK_Mode => On`.

- `make test` builds and runs checks.
- `make prove` runs Level 2 proof with CVC5, warnings, and checks as errors.
