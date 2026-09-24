# Muller's Method — Ada 2023

Educational, self-contained Ada 2023 package implementing **Muller's method**
— an **open** scalar root finder that fits a **parabola** through the last
three iterates $(x_{i-2},f_{i-2})$, $(x_{i-1},f_{i-1})$, $(x_i,f_i)$ and takes
the parabolic root closest to $x_i$ as the next guess. Due to **David E. Muller
(1956)**. Compared with the **secant** method (a line through two points),
Muller uses a quadratic interpolant and typically converges with order about
$1.84$ for a simple root — faster than secant ($\varphi\approx 1.618$), without
needing $f'$.

Based on [Wikipedia: Muller's method](https://en.wikipedia.org/wiki/Muller%27s_method).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (root-finding series):

| Package | Role |
| --- | --- |
| [Ada-Newtons-Method](https://github.com/RobertBoettcherSF/Ada-Newtons-Method) | Newton–Raphson (analytic $f'$) |
| [Ada-Ridders-Method](https://github.com/RobertBoettcherSF/Ada-Ridders-Method) | Bracketed Ridders |
| [Ada-Secant-Method](https://github.com/RobertBoettcherSF/Ada-Secant-Method) | Secant line (forthcoming) |
| [Ada-Mullers-Method](https://github.com/RobertBoettcherSF/Ada-Mullers-Method) | This package (parabola) |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Root of interpolating parabola | Open method (three starts) |
| **Update** | Wikipedia $x_3$ with $\mathrm{sign}(b)\sqrt{\cdot}$ | Closest root to $x_2$ |
| **Arithmetic** | Real-only educational path | Negative discriminant $\to$ `Degenerate` |
| **Stop** | $\|f\|\le\mathrm{Tol}$ or $\|\Delta x\|\le\mathrm{Tol}$ | Or max iterations |
| **API** | `Objective_Fn` access-to-function | `Result` with `Status` |
| **Limits** | Educational `Real` (digits 15) | Not a production solver |

## Brief history

**David E. Muller** presented the method in 1956 as a third-order recurrence
related to the secant method: instead of a secant **line** through two graph
points, Muller builds a **parabola** through three and advances to a root of
that parabola. The method can find complex roots when implemented over
$\mathbb{C}$; this package keeps a **real-valued** educational path (non-negative
discriminant) suitable for typical real-root demos. For a simple root with
smooth $f$, the asymptotic order $p$ solves $p^3-p^2-p-1=0$, so $p\approx 1.84$.

## Method

Given three distinct approximations $x_0,x_1,x_2$ and $f_i=f(x_i)$, set

$$
h_0=x_1-x_0,\qquad h_1=x_2-x_1,
$$

$$
\delta_0=\frac{f(x_1)-f(x_0)}{h_0},\qquad
\delta_1=\frac{f(x_2)-f(x_1)}{h_1}.
$$

The unique parabola $P(x)=a(x-x_2)^2+b(x-x_2)+c$ through the three points has

$$
a=\frac{\delta_1-\delta_0}{h_1+h_0},\qquad
b=a\,h_1+\delta_1,\qquad
c=f(x_2).
$$

The next iterate (root of $P$ closest to $x_2$) is the Wikipedia formula

$$
x_3=x_2-\frac{2c}{b+\operatorname{sign}(b)\,\sqrt{b^{2}-4ac}}.
$$

(Equivalently: if $b\ge 0$ take $+$ under the radical in the denominator;
if $b<0$ take $-$.) Then shift $(x_0,x_1,x_2)\leftarrow(x_1,x_2,x_3)$ and
repeat until $|x_3-x_2|\le\varepsilon$ or $|f(x_3)|\le\varepsilon$.

**Real-only path.** When $b^{2}-4ac<0$ the parabolic roots are complex.
This package returns `Status => Degenerate` rather than entering
`Ada.Numerics.Generic_Complex_Types` (documented as an optional extension).

Inline check: three starts must be pairwise distinct; a zero step
denominator is also `Degenerate`.

**Wikipedia demo.** For $f(x)=-x^{3}-x+7$ with starts $1,2,3$ and tolerance
$10^{-9}$, Muller yields the real root $\approx 1.7392038612200968$.

## API summary

```ada
type Real is digits 15;
type Objective_Fn is access function (X : Real) return Real;

function Sign (X : Real) return Real;
function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean;
function Starts_Distinct (X0, X1, X2 : Real) return Boolean;

function Next_Point
  (X0, X1, X2 : Real; F0, F1, F2 : Real) return Real;

type Config is record
   Max_Iterations : Positive      := 100;
   Tol            : Positive_Real := 1.0E-10;
end record;

type Status_Kind is (Ok, Degenerate, Max_Iterations_Reached);

type Result is record
   Root, Final_F : Real;
   Iterations    : Natural;
   Success       : Boolean;
   Status        : Status_Kind;
end record;

function Find_Root
  (F : Objective_Fn; X0, X1, X2 : Real; Cfg : Config := (others => <>))
  return Result;

function Find_Root
  (F : Objective_Fn; X0, X1, X2 : Real;
   Tol : Positive_Real; Max_Iterations : Positive := 100)
  return Result;
```

- **`Starts_Distinct`** — `True` iff $X_0,X_1,X_2$ are pairwise distinct.
- **`Sign`** — classical $-1,0,+1$.
- **`Next_Point`** — single Wikipedia $x_3$ step (raises `Invalid_Argument`
  on coincident abscissae, zero denominator, or negative discriminant).
- **`Find_Root`** — full iteration; degenerate geometry or complex
  parabolic roots return `Success => False`, `Status => Degenerate`
  (no exception). A null `Objective_Fn` raises `Invalid_Argument`.

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision, not interval arithmetic.
- **Open method**: no bracket guarantee; poor starts may diverge or stall.
- **Real-only**: negative $b^{2}-4ac$ yields `Degenerate` (complex Muller
  is out of scope; optional future `Generic_Complex_Types` path).
- Three distinct initial guesses required; coincident starts are
  `Degenerate`.
- One new function evaluation per iteration after the three initial samples.
- Not a substitute for Brent / TOMS 748 or safeguarded hybrid solvers
  in production libraries.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pmullers_method.gpr
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
| `mullers_method.ads` | Package spec |
| `mullers_method.adb` | Package body |
| `mullers_method.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- David E. Muller, “A method for solving algebraic equations using an
  automatic computer,” *Mathematical Tables and Other Aids to Computation*,
  1956 (see Wikipedia).
- [Wikipedia: Muller's method](https://en.wikipedia.org/wiki/Muller%27s_method)
- Secant method (sibling package forthcoming) — line vs parabola.
