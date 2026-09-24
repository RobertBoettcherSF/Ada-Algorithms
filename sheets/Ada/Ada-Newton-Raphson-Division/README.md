# Newton–Raphson Division — Ada 2023

Educational, self-contained Ada 2023 package for **Newton–Raphson
division** — a *fast division* method that finds an approximate reciprocal
$X\approx 1/D$ by Newton iteration and multiplies by the dividend:

$$
X\leftarrow X(2-DX),\qquad Q=N\cdot X.
$$

Based on
[Wikipedia: Division algorithm — Newton–Raphson division](https://en.wikipedia.org/wiki/Division_algorithm#Newton%E2%80%93Raphson_division)
and
[Wikipedia: Newton–Raphson division](https://en.wikipedia.org/wiki/Newton%E2%80%93Raphson_division).

Educational `Long_Float` core with optional `Integer` wrappers (toward-zero
and floor) that verify $N=QD+R$. The reciprocal iteration is **reimplemented
here** (does not `with` the sibling multiplicative-inverse package).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Non-Restoring-Division](https://github.com/RobertBoettcherSF/Ada-Non-Restoring-Division)** — radix-$2$ non-restoring, digits $\{-1,1\}$
- **[Ada-Restoring-Division](https://github.com/RobertBoettcherSF/Ada-Restoring-Division)** — radix-$2$ restoring, digits $\{0,1\}$
- **[Ada-SRT-Division](https://github.com/RobertBoettcherSF/Ada-SRT-Division)** — radix-$2$ SRT, redundant digits $\{-1,0,1\}$
- **[Ada-Newton-Multiplicative-Inverse](https://github.com/RobertBoettcherSF/Ada-Newton-Multiplicative-Inverse)** — NR reciprocal / series inverse focus
- **Long division** — upcoming
- **Goldschmidt division** — upcoming
- **Division algorithms survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Reciprocal** | $X\leftarrow X(2-DX)$ | Two multiplies, one subtract |
| **Seed** | Dyadic scale + $(48-32M)/17$ | $M\in[\tfrac12,1)$; classic NR-division |
| **Quotient** | $Q=N\cdot X$ | `Divide_NR` / `Divide_NR_Detail` |
| **Convergence** | $\varepsilon_{i+1}=\varepsilon_i^{2}$ | Correct digits roughly **double** each step |
| **Integer** | Toward-zero / floor wrappers | Check $N=QD+R$ |
| **Oracle** | `Exact_Quotient`, `Exact_Integer_Divide` | `Long_Float` `/`; Integer `/`/`rem` |
| **Invalid** | `Invalid_Argument` / `Bad_Domain` | $D=0$ |

## Brief history

Slow division (restoring, non-restoring, SRT) produces about one quotient
digit per iteration. Fast methods — Newton–Raphson and Goldschmidt — start
from a reciprocal estimate and refine it with multiplications that map onto
hardware multipliers. Applying Newton’s method to $f(X)=1/X-D$ yields the
division-free update $X(2-DX)$. Quadratic convergence makes the technique
especially valuable for large integers and floating-point units that already
have a fast multiplier.

## Algorithm (this package)

**Goal.** Given dividend $N$ and nonzero divisor $D$, compute $Q=N/D$.

**Step 1 — seed.** Scale $|D|=M\cdot 2^{e}$ so $M\in[\tfrac12,1)$. Seed the
mantissa reciprocal with the classic linear Chebyshev approximant

$$
X_0=\frac{48}{17}-\frac{32}{17}M,
$$

then restore sign and the dyadic factor $2^{-e}$. The initial relative error
satisfies $|\varepsilon_0|\le 1/17\approx 0.059$.

**Step 2 — Newton reciprocal.** Iterate

$$
X_{i+1}=X_i(2-D X_i)
$$

until $|D X-1|$ (or a relative step) is below tolerance. With
$\varepsilon_i=1-D X_i$,

$$
\varepsilon_{i+1}=\varepsilon_i^{2},
$$

so the number of correct digits roughly **doubles** every successful
iteration (quadratic convergence).

**Step 3 — multiply.** Form the quotient

$$
Q=N\cdot X_S.
$$

**Integer wrappers.** Convert the float quotient toward zero (Ada `/`/`rem`
style) or with mathematical floor, then set $R=N-QD$ and repair rare
off-by-ones so the identity $N=QD+R$ holds with $|R|<|D|$ (toward zero) or
the usual floor remainder range.

**Worked check.** $N=15$, $D=3$: reciprocal $\to\tfrac13$, $Q=5$.
$D\cdot X\approx 1$ to working precision for classroom magnitudes.

## API summary

| Symbol | Role |
| --- | --- |
| `Reciprocal_Result` | `(Value, Iterations, Status)` for $1/D$ |
| `Division_Result` | `(Quotient, Reciprocal, Iterations, Status)` |
| `Integer_Division_Result` | `(Quotient, Remainder)` |
| `Status_Kind` | `Converged`, `Bad_Domain` ($D=0$), `Max_Iterations_Reached` |
| `Reciprocal_Newton(D,Tol,Max_Iter)` | NR reciprocal; never raises |
| `Divide_NR_Detail(N,D,...)` | Full NR division record; never raises |
| `Divide_NR(N,D)` | Float quotient; raises `Invalid_Argument` if not converged |
| `Divide_Integer_Toward_Zero(N,D)` | Integer $Q,R$ toward zero; raises if $D=0$ |
| `Divide_Integer_Floor(N,D)` | Integer floor $Q$ + remainder; raises if $D=0$ |
| `Exact_Quotient(N,D)` | Oracle `Long_Float` `/` |
| `Exact_Reciprocal(D)` | Oracle $1/D$ |
| `Exact_Integer_Divide(N,D)` | Oracle Integer `/` and `rem` |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `Invalid_Argument` | Exception on $D=0$ / failed convenience calls |

## Limits and caveats

- **Educational `Long_Float`** — double precision; not a multiprecision
  reciprocal kernel or IEEE correctly-rounded division replacement.
- **Domain** — $D=0$ yields `Bad_Domain` / `Invalid_Argument`.
- **Integer wrappers** — go through float NR then round; intended for
  moderate classroom magnitudes, with oracle fallback / remainder repair.
- **Initial guess** — dyadic + linear seed is ample for typical magnitudes;
  subnormals / overflow extremes are out of scope.
- **Digit doubling** — quadratic only near a good seed; pathological seeds
  are avoided by the documented scaling strategy.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pnewton_raphson_division.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `newton_raphson_division.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
newton_raphson_division.ads
newton_raphson_division.adb
newton_raphson_division.gpr
tests.adb
```

## References

1. [Wikipedia: Division algorithm — Newton–Raphson division](https://en.wikipedia.org/wiki/Division_algorithm#Newton%E2%80%93Raphson_division)
2. [Wikipedia: Newton–Raphson division](https://en.wikipedia.org/wiki/Newton%E2%80%93Raphson_division)
3. [Wikipedia: Newton’s method — Multiplicative inverses](https://en.wikipedia.org/wiki/Newton's_method#Multiplicative_inverses_of_numbers_and_power_series)
