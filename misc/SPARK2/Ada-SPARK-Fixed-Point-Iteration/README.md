# Ada-SPARK-Fixed-Point-Iteration

PLACEHOLDER: one hard-wired map run for 10 steps; no general function and no convergence test; see tools/vv/hidden_stub.csv

A bounded fixed-point iteration converging toward a target. The package is bounded and compiled in SPARK mode.

- `make test` builds and runs assertions.
- `make prove` runs level-2 CVC5 proofs with warnings and checks treated as errors.
