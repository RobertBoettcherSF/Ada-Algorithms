# Ada-SPARK-Find-Center-Of-Star-Graph

Bounded star-center search on a 16-node edge list.

The implementation is deliberately bounded and uses `SPARK_Mode => On`.

- `make test` builds and runs the checks.
- `make prove` runs Level 2 CVC5 proof with warnings and checks treated as errors.

## Input and answer (V&V sweep, 2026-10-09)

`Find_Center` counts each vertex's degree and returns the first vertex of
degree 15 (an endpoint of all 15 edges), or 0 when there is none. For a
star graph that is its centre. For any simple graph (no self-loop, no
repeated edge) a vertex of degree 15 touches every edge, so the answer is
exact: the centre, or 0 when the edge list is not a star. An edge list with
self-loops is not a graph this problem defines: a loop adds 2 to its
vertex's degree, so a vertex can reach 15 without touching every edge, and
the answer is then not a centre. The degree loop has no cap: after E edges
no degree exceeds 2 * E <= 30, which the proof checks (loop invariant).
Own checks: `own_checks.adb`, sources in `tests/SOURCES.txt`.
