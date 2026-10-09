# Ada-SPARK-Cosine-Distance

The bounded squared cosine distance for three components, scaled by 1000 to avoid floating point.

- `make test` builds and runs executable assertions.
- `make prove` runs full bounded SPARK level-2 proofs with CVC5, warnings, and checks treated as errors.

## V&V sweep notes (agent A3)

`Distance` returns 1000 - floor (1000 * Dot^2 / (|A|^2 |B|^2)); when either
vector is zero the cosine is undefined and `Distance` returns 0 by
convention. Tests: hand-worked values in `tests.adb` and an exhaustive
check of all 4,096 pairs in `own_checks.adb` (see `tests/SOURCES.txt`).
