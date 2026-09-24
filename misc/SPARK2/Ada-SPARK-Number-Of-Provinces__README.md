# Ada-SPARK-Number-Of-Provinces

Bounded union-find count for up to 16 provinces.

The implementation is deliberately bounded and uses `SPARK_Mode => On`.

- `make test` builds and runs the checks.
- `make prove` runs Level 2 CVC5 proof with warnings and checks treated as errors.
