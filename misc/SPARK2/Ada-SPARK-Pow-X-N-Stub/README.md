# Ada-SPARK-Pow-X-N-Stub

Integer power $x^n$ by repeated squaring ($O(\log n)$ multiplications) for every `Integer` $x$ and `Natural` $n$.

`Power (X, N, Result, Ok)`: `Ok` is False exactly when $x^n$ does not fit in `Integer` (then `Result = 0`). Proved (Silver, `--level=2`) with the functional postconditions $x^0 = 1$, $x^1 = x$, $1^n = 1$; the general value is checked by the tests against naive multiplication for $x \in -50..50$, $n \in 0..40$, plus edge cases such as $(-2)^{31}$ = `Integer'First` and $2^{31}$ (overflow).

Earlier this folder covered $x \in 0..4$, $n \in 0..5$ with a case table.

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
