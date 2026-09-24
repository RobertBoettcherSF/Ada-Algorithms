# Newton’s Method — Multiplicative Inverses — Ada 2023

Educational, self-contained Ada 2023 package implementing **Newton–Raphson
division / reciprocal iteration**: find $x=1/a$ by Newton on
$f(x)=1/x-a$, using only multiplication and subtraction,

$$
x_{n+1}=x_n(2-a x_n).
$$

Also provides **division via reciprocal** ($b/a=b\cdot(1/a)$) and a light
**truncated Newton lift** for formal power-series inverses (degree $\le 8$).
Educational `Long_Float`.

Based on
[Wikipedia: Newton’s method § Multiplicative inverses of numbers and power series](https://en.wikipedia.org/wiki/Newton's_method#Multiplicative_inverses_of_numbers_and_power_series)
and
[Wikipedia: Multiplicative inverse](https://en.wikipedia.org/wiki/Multiplicative_inverse).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (related numeric / arithmetic helpers):

- **[Ada-Rounding-Functions](https://github.com/RobertBoettcherSF/Ada-Rounding-Functions)** — directed / nearest rounding modes
- **[Ada-Nth-Root](https://github.com/RobertBoettcherSF/Ada-Nth-Root)** — Newton / Halley $n$-th roots
- **Multiplicative inverse Algorithms** — upcoming
- **Toom–Cook** — upcoming
- **Schönhage–Strassen** — upcoming
- **Karatsuba** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Reciprocal** | $x\leftarrow x(2-ax)$ | Two multiplies, one subtract |
| **Seed** | Dyadic scale + $(48-32M)/17$ | $M\in[\tfrac12,1)$; classic NR-division |
| **Division** | $b\cdot\mathrm{reciprocal}(a)$ | Optional convenience |
| **Series** | Truncated Newton lift | Formal $p\cdot q\equiv 1\bmod t^{d+1}$, $d\le 8$ |
| **Oracle** | `Exact_Reciprocal` $=1/A$ | Comparison only |
| **Status** | `Converged` / `Bad_Domain` / `Max_Iterations_Reached` | $A=0$ or $p_0=0$ → `Bad_Domain` |
| **Helpers** | `Near`, `Abs_Error`, `Rel_Error` | Test / teaching |

## Brief history

Finding reciprocals without a dedicated divider is ancient hardware practice:
Goldschmidt and Newton–Raphson division refine an approximate reciprocal with
multiply–accumulate steps that map cleanly onto multipliers. Isaac Newton’s
tangent method applied to $f(x)=1/x-a$ collapses to the elegant update
$x(2-ax)$, needing no division at all. The same algebraic identity lifts
verbatim to rings of formal power series, yielding fast series inversion
used in computer algebra. This package stays with the educational
`Long_Float` presentation from Wikipedia’s multiplicative-inverses section.

## Algorithm (this package)

**Goal.** For nonzero real $a$, compute $x=1/a$. Equivalently, solve
$f(x)=1/x-a=0$. With $f'(x)=-1/x^2$,

$$
x_{n+1}=x_n-\frac{f(x_n)}{f'(x_n)}=x_n(2-a x_n).
$$

**Initial guess.** Scale $|a|=M\cdot 2^{e}$ so $M\in[\tfrac12,1)$; seed the
mantissa reciprocal with the classic linear approximant

$$
\frac{1}{M}\approx\frac{48}{17}-\frac{32}{17}M,
$$

then restore sign and the dyadic factor $2^{-e}$. Quadratic convergence
then doubles correct digits each successful step.

**Division.** Optionally form $b/a$ as $b\cdot x$ after the reciprocal
solve (Newton–Raphson division’s second half).

**Power series.** For $p(t)=p_0+p_1 t+\cdots+p_d t^d$ with $p_0\neq 0$,
iterate the same map in the truncated series ring

$$
q\leftarrow\mathrm{trunc}_d\bigl(q\cdot(2-p\cdot q)\bigr),
$$

starting from $q_0=1/p_0$, until $\mathrm{trunc}_d(p\cdot q)=1$. Cap
$d\le 8$ (`Max_Series_Degree`).

**Worked check.** $a=2$: Newton recovers $x=\tfrac12$. $a=\pi$:
$a\cdot x\approx 1$ to working precision. Series $p=1+t$ recovers the
geometric truncation $1-t+t^2-\cdots$.

## API summary

| Symbol | Role |
| --- | --- |
| `Reciprocal_Result` | `(Value, Iterations, Status)` |
| `Status_Kind` | `Converged`, `Bad_Domain` ($A=0$ / $p_0=0$), `Max_Iterations_Reached` |
| `Reciprocal_Newton(A,Tol,Max_Iter)` | NR reciprocal; never raises |
| `Reciprocal(A)` | Convenience; raises `Invalid_Argument` if not converged |
| `Divide_Newton(B,A,...)` | Quotient $B\cdot(1/A)$; never raises |
| `Divide(B,A)` | Convenience; raises on failure |
| `Exact_Reciprocal(A)` | Oracle $1/A$; raises if $A=0$ |
| `Series_Inverse_Newton(P,Degree,...)` | Truncated series inverse; $d\le 8$ |
| `Series_Result` | `(Coeffs, Degree, Iterations, Status)` |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `Invalid_Argument` | Exception from convenience / oracle on failure |

## Limits and caveats

- **Educational `Long_Float`** — double precision; not a multiprecision
  reciprocal kernel or IEEE division replacement.
- **Domain** — $A=0$ and series $p_0=0$ yield `Bad_Domain` /
  `Invalid_Argument`. No complex / modular inverses here.
- **Initial guess** — dyadic + linear seed is ample for classroom
  magnitudes; subnormals / overflow extremes are out of scope.
- **Series** — formal truncated algebra only (degree $\le 8$); not a
  full computer-algebra series type. Higher-degree or sparse series
  remain future work alongside dedicated multiplicative-inverse
  algorithm packages.
- **Convergence** — quadratic near a simple reciprocal; pathological
  seeds are avoided by the documented scaling strategy.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pnewton_multiplicative_inverse.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `newton_multiplicative_inverse.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
newton_multiplicative_inverse.ads
newton_multiplicative_inverse.adb
newton_multiplicative_inverse.gpr
tests.adb
```

## References

1. [Wikipedia: Newton’s method — Multiplicative inverses of numbers and power series](https://en.wikipedia.org/wiki/Newton's_method#Multiplicative_inverses_of_numbers_and_power_series)
2. [Wikipedia: Multiplicative inverse](https://en.wikipedia.org/wiki/Multiplicative_inverse)
3. [Wikipedia: Division algorithm — Newton–Raphson division](https://en.wikipedia.org/wiki/Division_algorithm#Newton%E2%80%93Raphson_division)
4. Atkinson, K. E. — An introduction to numerical analysis (Newton iteration).
5. Siblings: [Ada-Rounding-Functions](https://github.com/RobertBoettcherSF/Ada-Rounding-Functions),
   [Ada-Nth-Root](https://github.com/RobertBoettcherSF/Ada-Nth-Root);
   upcoming Multiplicative inverse Algorithms, Toom–Cook, Schönhage–Strassen, Karatsuba.
