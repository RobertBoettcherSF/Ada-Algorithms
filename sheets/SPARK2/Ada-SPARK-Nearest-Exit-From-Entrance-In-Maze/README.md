# Ada-SPARK-Nearest-Exit-From-Entrance-In-Maze

Nearest Exit from Entrance in Maze workload over a bounded 8x8 grid.

The implementation deliberately fixes the input to an 8x8 binary grid so the
example stays bounded and is suitable for SPARK proof. `Open_Count` computes the
count of open cells. as a small, fully proved kernel.

## Verify

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```
