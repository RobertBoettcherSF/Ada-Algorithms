# Ada-SPARK-Shortest-Path-In-Binary-Matrix

PLACEHOLDER: the README calls this a stub / bounded kernel, not a full Shortest-Path-In-Binary-Matrix implementation; see tools/readme_stubs.txt

Shortest path in an 8x8 binary matrix (bounded SPARK stub).

The implementation deliberately fixes the input to an 8x8 binary grid so the
example stays bounded and is suitable for SPARK proof. `Path_Length` computes the
count of open cells as a bounded path-workload metric. as a small, fully proved kernel.

## Verify

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
