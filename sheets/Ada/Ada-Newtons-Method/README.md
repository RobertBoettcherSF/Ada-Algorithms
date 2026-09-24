# Newton's Method (Newton–Raphson) — Ada 2023

Educational, self-contained Ada 2023 package implementing the **Newton–Raphson**
scalar **root-finding** method: given $f$ and its derivative $f'$, iterate the
tangent-line update

$$
x_{n+1}=x_n-\frac{f(x_n)}{f'(x_n)}
$$

until $|f(x)|$ (or the step) is within tolerance. For a **simple** root with
$f'(\alpha)\neq 0$ and $f$ smooth nearby, convergence is at least **quadratic**:
the number of correct digits roughly doubles each successful step.

Based on [Wikipedia: Newton's method](https://en.wikipedia.org/wiki/Newton%27s_method).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (root-finding series):

| Package | Role |
| --- | --- |
| [Ada-Ridders-Method](https://github.com/RobertBoettcherSF/Ada-Ridders-Method) | Bracketed Ridders |
| [Ada-Newtons-Method](https://github.com/RobertBoettcherSF/Ada-Newtons-Method) | This package (1-D root finding) |
| [Ada-Newtons-Method-in-Optimization](https://github.com/RobertBoettcherSF/Ada-Newtons-Method-in-Optimization) | Unconstrained minimize via Hessian (different problem) |
| [Ada-Halleys-Method](https://github.com/RobertBoettcherSF/Ada-Halleys-Method) | Halley (forthcoming) |
| [Ada-Mullers-Method](https://github.com/RobertBoettcherSF/Ada-Mullers-Method) | Muller (forthcoming) |
| [Ada-False-Position-Method](https://github.com/RobertBoettcherSF/Ada-False-Position-Method) | Regula falsi (forthcoming) |
| [Ada-Bisection-Method](https://github.com/RobertBoettcherSF/Ada-Bisection-Method) | Classic bisection (forthcoming) |

**Not the same problem as** [Ada-Newtons-Method-in-Optimization](https://github.com/RobertBoettcherSF/Ada-Newtons-Method-in-Optimization):
that sibling applies Newton to $\nabla f=0$ with a Hessian solve in $\mathbb{R}^n$.
This package finds zeros of a scalar $f:\mathbb{R}\to\mathbb{R}$ with an analytic
$f'$. Complex / multivariate Newton is **Forthcoming** only; keep the API 1-D real.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Root of tangent line at $x_n$ | Open method (no bracket required) |
| **Update** | $x\leftarrow x-\lambda f(x)/f'(x)$ | $\lambda=1$ classical; $\lambda\in(0,1]$ damped |
| **Derivative** | Analytic `Derivative_Fn` | Required (no FD in this package) |
| **Guard** | $\|f'\|<\mathrm{Min\_Derivative}$ | `Status => Degenerate` |
| **Safeguard** | Optional backtrack on growing $\|f\|$ | Light educational damping |
| **Stop** | $\|f\|\le\mathrm{Tol}$ or $\|\Delta x\|\le\mathrm{Tol}$ | Or max iterations |
| **API** | `Objective_Fn` + `Derivative_Fn` | `Result` with `Status` |
| **Limits** | Educational `Real` (digits 15) | Not a production solver |

## Brief history

Babylonian / Heron square-root iteration is a special case of Newton on
$f(x)=x^2-a$. Newton and Raphson developed polynomial forms in the 17th century;
Simpson (1740) stated the calculus form used today. The method remains a default
local solver when $f'$ is available and a good initial guess is known.

## Method

Linearize $f$ at the current guess $x_n$:

$$
f(x)\approx f(x_n)+f'(x_n)\,(x-x_n).
$$

Set the right-hand side to zero and solve for the next guess (assuming
$f'(x_n)\neq 0$):

$$
x_{n+1}=x_n-\frac{f(x_n)}{f'(x_n)}.
$$

**Square roots.** For $f(x)=x^2-a$ one recovers Heron's iteration

$$
x_{n+1}=\frac12\Bigl(x_n+\frac{a}{x_n}\Bigr).
$$

**Damped / safeguarded step (optional).** With damping factor
$\lambda\in(0,1]$:

$$
x_{n+1}=x_n-\lambda\frac{f(x_n)}{f'(x_n)}.
$$

When `Use_Safeguard` is enabled, $\lambda$ is halved while $|f|$ increases
(educational backtracking; not a full trust-region or hybrid Brent scheme).

Inline check: if $|f'(x_n)|$ is tiny, the tangent is nearly horizontal and the
step is undefined or unstable — this package returns `Degenerate` rather than
dividing by zero.

## API summary

```ada
type Real is digits 15;
type Objective_Fn  is access function (X : Real) return Real;
type Derivative_Fn is access function (X : Real) return Real;

function Sign (X : Real) return Real;
function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean;
function Next_Point
  (X, F_Val, F_Deriv : Real; Damping : Positive_Real := 1.0) return Real;

type Config is record
   Max_Iterations : Positive      := 100;
   Tol            : Positive_Real := 1.0E-10;
   Min_Derivative : Positive_Real := 1.0E-14;
   Damping        : Positive_Real := 1.0;   -- λ ∈ (0,1]
   Use_Safeguard  : Boolean       := False;
end record;

type Status_Kind is (Ok, Degenerate, Max_Iterations_Reached);

type Result is record
   Root, Final_F : Real;
   Iterations    : Natural;
   Success       : Boolean;
   Status        : Status_Kind;
end record;

function Find_Root
  (F : Objective_Fn; F_Prime : Derivative_Fn; X0 : Real;
   Cfg : Config := (others => <>)) return Result;

function Find_Root
  (F : Objective_Fn; F_Prime : Derivative_Fn; X0 : Real;
   Tol : Positive_Real; Max_Iterations : Positive := 100) return Result;
```

- **`Next_Point`** — one Wikipedia step $x-\lambda f/f'$ (raises
  `Invalid_Argument` on exact zero $f'$).
- **`Find_Root`** — full iteration; tiny $|f'|$ returns
  `Success => False`, `Status => Degenerate` (no exception).
  A null `Objective_Fn` or `Derivative_Fn` raises `Invalid_Argument`.
- Sample objectives ship with matching analytic primes (`Poly_Quad` /
  `Poly_Quad_Prime`, `Sin_Fn` / `Sin_Fn_Prime`, `Sqrt_Obj` for $x^2-a$, …).

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision, not interval arithmetic.
- **Open method**: no bracket guarantee; a bad $x_0$ may diverge, cycle, or
  jump to a distant root.
- Requires an **analytic derivative**; finite-difference Newton / secant is
  out of scope here.
- Horizontal tangents ($f'\approx 0$) → `Degenerate`.
- Multiple roots: rate drops to linear unless multiplicity is handled
  (not implemented).
- Optional damping / safeguard is pedagogical, not a production globalization.
- Complex Newton fractals and multivariate Newton systems are **Forthcoming**
  only — this package stays **1-D real**.
- Sibling **optimization** Newton solves $\nabla f=0$ with a Hessian; do not
  confuse the two APIs.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pnewtons_method.gpr
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
| `newtons_method.ads` | Package spec |
| `newtons_method.adb` | Package body |
| `newtons_method.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Newton's method](https://en.wikipedia.org/wiki/Newton%27s_method)
- Heron's method / Babylonian square-root iteration (special case $x^2-a$).
- [Ada-Newtons-Method-in-Optimization](https://github.com/RobertBoettcherSF/Ada-Newtons-Method-in-Optimization)
  — Hessian / Armijo sibling (minimize $f$, not find roots of $f$).
- Householder / Halley methods (higher-order siblings, forthcoming).
