# Ada-SPARK-As-Far-From-Land-As-Possible

As Far from Land as Possible workload over a bounded 8x8 grid.

The implementation deliberately fixes the input to an 8x8 binary grid so the
example stays bounded and is suitable for SPARK proof. `Land_Count` computes the
count of land cells. as a small, fully proved kernel.

## Verify

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```
