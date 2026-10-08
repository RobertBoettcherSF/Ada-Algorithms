# Ada-SPARK-Matrix-Cells-In-Distance-Order

Small bounded Ada SPARK implementation of the corresponding array or matrix exercise.

```sh
make test
make prove
```

`Order_From (Origin, Cells)` lists all 16 cells of the 4x4 matrix in
non-decreasing Manhattan distance from `Origin`; cells at the same distance
stay in row-major order.
