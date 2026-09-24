# Nth Root Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the **nth root
algorithm** for real radicands: Newton (and optional Halley) iteration for
the principal root $r = x^{1/n}$, special-case `Sqrt` / `Cbrt` wrappers, a
careful integer power helper, and a binary-search **integer floor** nth
root. Cap $n\in[1..32]$; educational `Long_Float`.

Based on [Wikipedia: Nth root algorithm](https://en.wikipedia.org/wiki/Nth_root_algorithm)
and [Wikipedia: Nth root](https://en.wikipedia.org/wiki/Nth_root).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (related numeric helpers):

- **[Ada-Binary-Splitting](https://github.com/RobertBoettcherSF/Ada-Binary-Splitting)** — product-tree series
- **[Ada-Kahan-Summation](https://github.com/RobertBoettcherSF/Ada-Kahan-Summation)** — compensated summation
- **Methods of computing square roots** — upcoming
- **Alpha max plus beta min** — upcoming
- **Spigot** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Newton** | $y\leftarrow\frac{1}{n}\bigl((n-1)y+x/y^{n-1}\bigr)$ | Wikipedia efficient form |
| **Halley** | Cubic update from $f(y)=y^n-x$ | Fewer iters, educational |
| **Sqrt / Cbrt** | $n=2$ / $n=3$ wrappers | Negatives only for odd $n$ |
| **Pow_Int** | Successive squaring | Avoids non-integer `**` |
| **Integer root** | Binary search floor $r$ | $r^n\le x < (r+1)^n$ |
| **Status** | `Converged` / `Bad_Domain` / `Max_Iterations_Reached` | `Bad_Domain` ≡ invalid arg |
| **Cap** | $n\le 32$ | `Max_Degree = 32` |

## Brief history

Root extraction is ancient: Heron of Alexandria’s square-root iteration is
Newton’s method for $n=2$; digit-by-digit (Viète) and Ruffini–Horner-style
schemes (al-Kashi and others) handled general $n$. Isaac Newton’s binomial
series and the Newton–Raphson tangent method give the modern recurrence for
$f(y)=y^n-x=0$, refined by Raphson. The compact one-exponentiation form

$$
y_{k+1}=\frac{1}{n}\left((n-1)y_k+\frac{x}{y_k^{n-1}}\right)
$$

is the standard educational presentation on Wikipedia’s nth-root algorithm
page.

## Algorithm (this package)

**Goal.** For integer degree $n\ge 1$ and radicand $x$ (with $x\ge 0$ when
$n$ is even; any real $x$ when $n$ is odd), compute the principal real root
$r$ satisfying $r^n=x$ (negative $r$ when $x<0$ and $n$ odd).

**Newton.** Start from a crude positive guess $y_0$ for $|x|$, then iterate
the update above until $|y_{k+1}-y_k|$ is below a tolerance (absolute or
relative). Restore the sign of $x$ for odd $n$. Special cases: $n=1$ returns
$x$ immediately; $x=0$ returns $0$.

**Halley (optional).** For $f(y)=y^n-x$,

$$
y\leftarrow y\cdot\frac{(n-1)y^n+(n+1)x}{(n+1)y^n+(n-1)x},
$$

typically cubically convergent near a simple root — useful contrast to
Newton’s quadratic rate.

**Integer floor root.** Binary search for the largest natural $r$ with
$r^n\le x$ (overflow-safe powering).

**Worked check.** $n=2$, $x=2$: Newton recovers $\sqrt{2}\approx
1.41421356237$. $n=3$, $x=8$ yields $2$; $n=4$, $x=16$ yields $2$.

## API summary

| Symbol | Role |
| --- | --- |
| `Degree` | Subtype $1..32$ (`Min_Degree` .. `Max_Degree`) |
| `Root_Result` | `(Value, Iterations, Status)` |
| `Status_Kind` | `Converged`, `Bad_Domain` (invalid arg), `Max_Iterations_Reached` |
| `Root_Newton(X,N,Tol,Max_Iter)` | Newton extraction; never raises |
| `Root(X,N)` | Convenience; raises `Invalid_Argument` if not converged |
| `Sqrt`, `Cbrt` | $n=2$ / $n=3$ wrappers |
| `Root_Halley(...)` | Halley extraction; never raises |
| `Integer_Nth_Root(X,N)` | Floor natural root |
| `Pow_Int(Y,K)` | $Y^K$ by successive squaring |
| `Near`, `Abs_Error` | Numeric helpers |
| `Invalid_Argument` | Exception from `Root` / `Sqrt` / `Cbrt` on failure |

## Limits and caveats

- **Educational `Long_Float`** — double precision; not a multiprecision
  kernel. Tests compare against `X**(1.0/N)` where Ada’s `**` is defined.
- **Cap** — `Max_Degree = 32`. Larger $n$ needs care with overflow /
  underflow in $y^{n-1}$.
- **Domain** — even $n$ rejects $x<0$ (`Bad_Domain` / `Invalid_Argument`).
  Odd $n$ returns the real negative root.
- **Initial guess** — doubling/halving from $1$ so $y^n$ brackets $|x|$
  before Newton; fine for classroom radicands.
- **Halley** — faster near the root; still the same domain rules.
- **Integer root** — floor only; overflow in intermediate powers is treated
  as “too large”.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pnth_root.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `nth_root.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
nth_root.ads
nth_root.adb
nth_root.gpr
tests.adb
```

## References

1. [Wikipedia: Nth root algorithm](https://en.wikipedia.org/wiki/Nth_root_algorithm)
2. [Wikipedia: Nth root](https://en.wikipedia.org/wiki/Nth_root)
3. Atkinson, K. E. — An introduction to numerical analysis (Newton for roots).
4. Siblings: [Ada-Binary-Splitting](https://github.com/RobertBoettcherSF/Ada-Binary-Splitting),
   [Ada-Kahan-Summation](https://github.com/RobertBoettcherSF/Ada-Kahan-Summation);
   upcoming Methods of computing square roots, Alpha max plus beta min, Spigot.
