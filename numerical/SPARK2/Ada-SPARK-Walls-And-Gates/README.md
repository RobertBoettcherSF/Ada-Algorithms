# Ada-SPARK-Walls-And-Gates

Walls and gates workload over a bounded 8x8 grid.

The implementation deliberately fixes the input to an 8x8 binary grid so the
example stays bounded and is suitable for SPARK proof. `Gate_Count` computes the
count of gates. as a small, fully proved kernel.

## Verify

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
