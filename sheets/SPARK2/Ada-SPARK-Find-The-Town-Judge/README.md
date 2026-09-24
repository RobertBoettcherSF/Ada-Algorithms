# Ada-SPARK-Find-The-Town-Judge

Bounded town-judge search over a 16-person trust matrix.

The implementation is deliberately bounded and uses `SPARK_Mode => On`.

- `make test` builds and runs the checks.
- `make prove` runs Level 2 CVC5 proof with warnings and checks treated as errors.
