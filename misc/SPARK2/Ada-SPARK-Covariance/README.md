# Ada-SPARK-Covariance

The bounded population covariance of three integer components: 1/3 of the sum of (A (I) - mean A) * (B (I) - mean B), truncated toward zero. (An earlier version centred every component on 5 instead of the mean.)

- `make test` builds and runs executable assertions.
- `make prove` runs full bounded SPARK level-2 proofs with CVC5, warnings, and checks treated as errors.
