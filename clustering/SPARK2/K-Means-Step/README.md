# K-Means-Step

One online update of two-centroid k-means on integer points 0 .. 100, in
SPARK.

- `Nearest (P, C1, C2)` is 1 when `|P - C1| <= |P - C2|` (ties go to
  cluster 1), else 2.
- `Step (P, C1, C2, N1, N2)` adds P to the nearest cluster: its centroid
  becomes the running mean `(C * N + P) / (N + 1)`, rounded down by integer
  division, and its count goes up by one. At most `Max_N = 8` points in
  total (`N1 + N2 < Max_N` before a step). Rounding down means a centroid
  can drift below the true mean of its points.

## Verification

```text
make test    # -gnatwa -gnat2022 -gnata
make prove   # Level 2, cvc5
```

`make test` built without `-gnata` before 2026-10-09, so the
`pragma Assert` checks in `tests.adb` were not executed. Own checks:
`own_checks.adb`, sources in `tests/SOURCES.txt`.
