# Ada-SPARK-All-Paths-From-Source-To-Target

Bounded source-to-target reachability for graphs with at most 16 nodes.

The implementation is deliberately bounded and uses `SPARK_Mode => On`.

- `make test` builds and runs the checks.
- `make prove` runs Level 2 CVC5 proof with warnings and checks treated as errors.
