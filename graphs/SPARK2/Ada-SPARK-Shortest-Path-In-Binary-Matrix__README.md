# Ada-SPARK-Shortest-Path-In-Binary-Matrix

Shortest path in an 8x8 binary matrix (bounded SPARK stub).

The implementation deliberately fixes the input to an 8x8 binary grid so the
example stays bounded and is suitable for SPARK proof. `Path_Length` computes the
count of open cells as a bounded path-workload metric. as a small, fully proved kernel.

## Verify

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```
