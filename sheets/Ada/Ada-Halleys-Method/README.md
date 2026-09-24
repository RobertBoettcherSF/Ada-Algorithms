# Halley's Method — Ada 2023

Educational, self-contained Ada 2023 package implementing **Halley's method**
(classic **rational** form): an open scalar root finder in the
**Householder** class (second member, after Newton). Given $f$, $f'$, and
$f''$, iterate

$$
x_{n+1}=x_n-\frac{2\,f(x_n)\,f'(x_n)}{2\bigl[f'(x_n)\bigr]^{2}-f(x_n)\,f''(x_n)}
$$

until $|f(x)|$ (or the step) is within tolerance. For a **simple** root with
$f'(\alpha)\neq 0$ and $f$ smooth nearby, convergence is **cubic**: the number
of correct digits roughly triples each successful step.

Based on [Wikipedia: Halley's method](https://en.wikipedia.org/wiki/Halley%27s_method).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (root-finding series):

| Package | Role |
| --- | --- |
| [Ada-Newtons-Method](https://github.com/RobertBoettcherSF/Ada-Newtons-Method) | Newton–Raphson (analytic $f'$) |
| [Ada-Mullers-Method](https://github.com/RobertBoettcherSF/Ada-Mullers-Method) | Muller parabola (no derivatives) |
| [Ada-Ridders-Method](https://github.com/RobertBoettcherSF/Ada-Ridders-Method) | Bracketed Ridders |
| [Ada-Halleys-Method](https://github.com/RobertBoettcherSF/Ada-Halleys-Method) | This package (Halley / $f,f',f''$) |

**Halley's irrational method** (third-order form that uses a square root) is
**Forthcoming** only — this package implements the classic **rational** Halley
update above. Multivariate Halley is likewise out of scope; keep the API
**1-D real**.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Root of linear-over-linear Padé / Householder order 2 | Open method (no bracket) |
| **Update** | $x\leftarrow x-(2ff')/(2(f')^{2}-ff'')$ | Cubic for simple roots |
| **Derivatives** | Analytic `Derivative_Fn` + `Second_Derivative_Fn` | Required (no FD here) |
| **Guard** | $\|2(f')^{2}-ff''\|<\mathrm{Min\_Denominator}$ | `Status => Degenerate` |
| **Also** | Vanishing Halley numerator with $\|f\|>\mathrm{Tol}$ | e.g. $f'=0$ away from a root |
| **Stop** | $\|f\|\le\mathrm{Tol}$ or $\|\Delta x\|\le\mathrm{Tol}$ | Or max iterations |
| **API** | `Objective_Fn` + $f'$ + $f''$ access-to-function | `Result` with `Status` |
| **Limits** | Educational `Real` (digits 15) | Not a production solver |

## Brief history

**Edmond Halley** (the astronomer) introduced this third-order root finder in
the early 18th century. It sits second in **Householder's methods** after
Newton–Raphson: Newton uses a linear (tangent) model; Halley effectively uses
a linear-over-linear Padé model and needs $f''$. When $f''$ is expensive or
unavailable, prefer Newton, secant, Muller, or a bracketed method (Ridders /
Brent). Halley also stated an **irrational** companion iteration (square-root
form); only the rational form is implemented here.

## Method

Taylor-expand $f$ through the quadratic term and eliminate the linear update
in favour of a corrected step (Wikipedia derivation via substituting Newton's
$\Delta x$ into the quadratic residual). The classic closed form is

$$
x_{n+1}=x_n-\frac{2\,f(x_n)\,f'(x_n)}{2\bigl[f'(x_n)\bigr]^{2}-f(x_n)\,f''(x_n)}.
$$

An equivalent rearrangement that highlights the Newton factor is

$$
x_{n+1}=x_n-\frac{f(x_n)}{f'(x_n)}\left[1-\frac12\cdot\frac{f(x_n)}{f'(x_n)}\cdot\frac{f''(x_n)}{f'(x_n)}\right]^{-1}.
$$

When $f''\equiv 0$ (affine $f$), Halley **reduces to Newton**:
$x\leftarrow x-f/f'$.

**Square roots.** For $f(x)=x^{2}-S$ one has $f'=2x$, $f''=2$, and Halley
specializes to a cubically convergent square-root iteration (Wikipedia
“Use of Halley's method to compute square roots”).

**Cubic convergence.** Near a simple root $\alpha$,

$$
|x_{n+1}-\alpha|\le K\,|x_n-\alpha|^{3}
$$

for some $K>0$ when $x_0$ is sufficiently close (Householder theory).

Inline check: if the Halley denominator $2(f')^{2}-ff''$ is tiny, the step is
undefined or unstable — this package returns `Degenerate` rather than dividing
by zero. A vanishing numerator $2ff'$ while $|f|$ is still large (typical when
$f'\approx 0$ away from a root) is likewise `Degenerate`.

## API summary

```ada
type Real is digits 15;
type Objective_Fn         is access function (X : Real) return Real;
type Derivative_Fn        is access function (X : Real) return Real;
type Second_Derivative_Fn is access function (X : Real) return Real;

function Sign (X : Real) return Real;
function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean;
function Next_Point
  (X, F_Val, F_Deriv, F_Second : Real) return Real;

type Config is record
   Max_Iterations  : Positive      := 100;
   Tol             : Positive_Real := 1.0E-10;
   Min_Denominator : Positive_Real := 1.0E-14;
end record;

type Status_Kind is (Ok, Degenerate, Max_Iterations_Reached);

type Result is record
   Root, Final_F : Real;
   Iterations    : Natural;
   Success       : Boolean;
   Status        : Status_Kind;
end record;

function Find_Root
  (F : Objective_Fn; F_Prime : Derivative_Fn;
   F_Second : Second_Derivative_Fn; X0 : Real;
   Cfg : Config := (others => <>)) return Result;

function Find_Root
  (F : Objective_Fn; F_Prime : Derivative_Fn;
   F_Second : Second_Derivative_Fn; X0 : Real;
   Tol : Positive_Real; Max_Iterations : Positive := 100) return Result;
```

- **`Next_Point`** — one Wikipedia Halley step
  $x-(2ff')/(2(f')^{2}-ff'')$ (raises `Invalid_Argument` on exact zero
  denominator).
- **`Find_Root`** — full iteration; tiny $|2(f')^{2}-ff''|$ (or vanishing
  numerator with large $|f|$) returns `Success => False`,
  `Status => Degenerate` (no exception). A null `Objective_Fn`,
  `Derivative_Fn`, or `Second_Derivative_Fn` raises `Invalid_Argument`.
- Sample objectives ship with matching analytic primes and seconds
  (`Poly_Quad` / `Poly_Quad_Prime` / `Poly_Quad_Second`,
  `Sin_Fn` / `Sin_Fn_Prime` / `Sin_Fn_Second`, `Sqrt_Obj` for $x^{2}-a$, …).

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision, not interval arithmetic.
- **Open method**: no bracket guarantee; a bad $x_0$ may diverge, cycle, or
  jump to a distant root.
- Requires **analytic** $f'$ and $f''$; finite-difference Halley is out of
  scope here.
- Tiny Halley denominator $\to$ `Degenerate`. Vanishing $f'$ away from a root
  likewise stalls the rational update.
- Multiple roots: asymptotic rate drops unless multiplicity is handled
  (not implemented).
- **Halley's irrational method** and multivariate Halley are **Forthcoming**
  only — this package stays **1-D real, rational form**.
- When $f''$ is costly or noisy, Newton or a derivative-free sibling
  (Muller / Ridders) may be preferable.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Phalleys_method.gpr
make test     # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. Zero warnings expected under
`-gnatwa -gnat2022`.

## Layout

Exactly seven root files (no `main.adb`):

| File | Role |
| --- | --- |
| `.gitignore` | Ignores `obj/`, `bin/` |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `halleys_method.ads` | Package spec |
| `halleys_method.adb` | Package body |
| `halleys_method.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Halley's method](https://en.wikipedia.org/wiki/Halley%27s_method)
- Householder's methods (Halley = order-2 member after Newton).
- [Ada-Newtons-Method](https://github.com/RobertBoettcherSF/Ada-Newtons-Method)
  — quadratic sibling with analytic $f'$ only.
- [Ada-Mullers-Method](https://github.com/RobertBoettcherSF/Ada-Mullers-Method)
  — derivative-free parabola sibling.
- [Ada-Ridders-Method](https://github.com/RobertBoettcherSF/Ada-Ridders-Method)
  — bracketed exponential-fit sibling.
