# Ada-SPARK-Broken-Calculator

Bounded SPARK broken calculator: the only operations are "double"
(X -> 2X) and "decrement" (X -> X - 1). `Minimum_Operations (Start, Target)`
returns the fewest operations turning `Start` into `Target`, for start and
target in `1 .. 32` (subtype `Operand`; from 0 nothing else is reachable).
It works backwards from the target (halve when even, otherwise add one)
until the target is at most the start, then counts the decrements.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
