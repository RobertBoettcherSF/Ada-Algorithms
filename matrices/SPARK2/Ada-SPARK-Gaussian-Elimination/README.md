# Ada-SPARK-Gaussian-Elimination

Bounded SPARK elimination step for a two-equation augmented system
`a11 x + a12 y = a13`, `a21 x + a22 y = a23` (integer entries `-10 .. 10`).

`Eliminate` returns an equivalent system (same solutions) whose row 2 has a
zero in column 1, using fraction-free elimination:
row 2 := row 2 * pivot - row 1 * a21. If `a11 = 0` and `a21 /= 0` the rows
are swapped first (partial pivoting), so the pivot is never zero; if the
whole first column is zero the system is returned unchanged.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
