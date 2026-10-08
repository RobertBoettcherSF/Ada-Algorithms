# Ada-SPARK-Convex-Hull-Graham

Bounded SPARK Graham-style stack scan for points supplied in sorted order.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

Input order expected by `Scan` (the Graham preparation step is left to the
caller): `Points (1)` is the pivot, the lowest point (smallest `Y`, then
smallest `X`); `Points (2 .. Number_Of_Points)` are sorted counter-clockwise
by angle around it, nearer points first on equal angles; all points are
distinct. `Hull (1 .. Hull_Count)` is then the convex hull counter-clockwise,
starting at the pivot, without collinear points.
