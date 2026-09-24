# Ada-SPARK-Open-The-Lock

Open the lock workload over a bounded 8x8 digit grid.

The implementation deliberately fixes the input to an 8x8 binary grid so the
example stays bounded and is suitable for SPARK proof. `Turn_Sum` computes the
bounded sum of wheel turns. as a small, fully proved kernel.

## Verify

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```
