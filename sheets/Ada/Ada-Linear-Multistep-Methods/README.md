# Linear multistep methods — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Linear multistep method](https://en.wikipedia.org/wiki/Linear_multistep_method):
**linear $k$-step** schemes for the scalar IVP $y'=f(t,y)$ that reuse past
solution and slope values instead of discarding them after each step (contrast
one-step Euler / Runge–Kutta).

A general linear multistep method takes the form

$$
\sum_{j=0}^{k} \alpha_{j}\, y_{n+j}
=
h \sum_{j=0}^{k} \beta_{j}\, f(t_{n+j}, y_{n+j}).
$$

The method is **explicit** when $\beta_{k}=0$ (Adams–Bashforth) and
**implicit** when $\beta_{k}\neq 0$ (Adams–Moulton, BDF). This package
implements a classroom catalogue of AB2–AB4, AM2 (trapezoidal rule), AM3,
BDF1 (backward Euler), and BDF2, with `Advance_*` helpers that bootstrap the
first $k-1$ steps internally (RK4 for Adams–Bashforth; same-family one-step
methods for AM3 / BDF2).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15).

Part of the **RobertBoettcherSF** Ada algorithm series.

Siblings:
[Ada-Euler-Integration](https://github.com/RobertBoettcherSF/Ada-Euler-Integration),
[Ada-Runge-Kutta](https://github.com/RobertBoettcherSF/Ada-Runge-Kutta),
[Ada-Trapezoidal-Rule-DE](https://github.com/RobertBoettcherSF/Ada-Trapezoidal-Rule-DE).
Next sheet rows may cover **Euler method** / **Backward Euler** (overlap with
AB1 / BDF1 here — those rows stay one-step focused; this package is the
multistep umbrella). Upcoming **Number theoretic algorithms** section after
the numerical DE / ODE track.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **RHS** | `ODE_Fn` access-to-function | $f(t,y)$ pointer style |
| **Taxonomy** | `Method_Kind`, `Order`, `Is_Explicit`, … | AB / AM / BDF catalogue |
| **Explicit** | `Adams_Bashforth_2/3/4_Step` | Need past $f$ history |
| **Implicit** | `Adams_Moulton_2/3_Step`, `BDF1/2_Step` | Newton or fixed-point |
| **Interval** | `Advance_*` | Bootstrap then multistep |
| **Coeffs** | `AB2_Beta_*`, `BDF2_Alpha_*`, … | Classic constants |
| **Zero-stab.** | `Characteristic_Polynomial_Roots_OK` | Root condition (light) |
| **Exact** | `Exact_Exponential` | $Y_0\,e^{\lambda t}$ |
| **Helpers** | `Near`, `Abs_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | $h\le 0$, bad history, … |

## Method

Suppose we solve

$$
y'=f(t,y),\qquad y(t_{0})=y_{0}.
$$

Approximations $y_{i}\approx y(t_{i})$ are sought on the mesh
$t_{i}=t_{0}+ih$. Multistep methods keep several past $y$ and $f$ values.

### Adams–Bashforth (explicit)

With $\alpha_{k}=1$, $\alpha_{k-1}=-1$, and remaining $\alpha_{j}=0$, the
$s$-step Adams–Bashforth method has order $s$. In advancing form:

$$
\begin{aligned}
y_{n+1}
&=
y_{n}+h\Bigl(\tfrac{3}{2}f_{n}-\tfrac{1}{2}f_{n-1}\Bigr)
&&\text{(AB2)},\\[0.5em]
y_{n+1}
&=
y_{n}+h\Bigl(\tfrac{23}{12}f_{n}-\tfrac{16}{12}f_{n-1}+\tfrac{5}{12}f_{n-2}\Bigr)
&&\text{(AB3)},\\[0.5em]
y_{n+1}
&=
y_{n}+h\Bigl(
\tfrac{55}{24}f_{n}-\tfrac{59}{24}f_{n-1}
+\tfrac{37}{24}f_{n-2}-\tfrac{9}{24}f_{n-3}
\Bigr)
&&\text{(AB4)}.
\end{aligned}
$$

### Adams–Moulton (implicit)

Allowing $\beta_{k}\neq 0$ raises the order by one relative to the $s$-step
Adams–Bashforth family. AM2 is the **trapezoidal rule** (also a one-step
RK / Crank–Nicolson flavour):

$$
y_{n+1}=y_{n}+\tfrac{h}{2}\bigl(f(t_{n+1},y_{n+1})+f(t_{n},y_{n})\bigr).
$$

AM3 (2-step, order 3):

$$
y_{n+1}
=
y_{n}+h\Bigl(
\tfrac{5}{12}f_{n+1}+\tfrac{8}{12}f_{n}-\tfrac{1}{12}f_{n-1}
\Bigr).
$$

### Backward differentiation formulas (BDF)

BDF methods set past $\beta_{j}=0$ and are popular for stiff problems:

$$
\begin{aligned}
y_{n+1}-y_{n}&=h\,f(t_{n+1},y_{n+1})
&&\text{(BDF1 = backward Euler)},\\[0.5em]
\tfrac{3}{2}y_{n+1}-2y_{n}+\tfrac{1}{2}y_{n-1}
&=
h\,f(t_{n+1},y_{n+1})
&&\text{(BDF2)}.
\end{aligned}
$$

Equivalently BDF2 advances as
$y_{n+1}=\tfrac{4}{3}y_{n}-\tfrac{1}{3}y_{n-1}+\tfrac{2}{3}h\,f_{n+1}$.

### Bootstrap (`Advance_*`)

A $k$-step method needs $k$ starting values. `Advance_AB*` takes the first
$k-1$ steps with an internal classic **RK4** starter (self-contained — no
sibling `with`), then applies the multistep formula. `Advance_AM3` seeds with
AM2; `Advance_BDF2` seeds with BDF1. Document this when comparing pure
multistep local error to fully bootstrapped global error.

### Zero-stability (root condition)

The first characteristic polynomial $\rho(\zeta)=\sum_{j=0}^{k}\alpha_{j}\zeta^{j}$
must satisfy: all roots $|\zeta|\le 1$, and roots on the unit circle simple.
`Characteristic_Polynomial_Roots_OK` checks this for the catalogue (exact
quadratic solve for AB2 / BDF2; textbook result for the rest). Example:
AB2 has $\rho(\zeta)=\zeta^{2}-\zeta$ (roots $0,1$); BDF2 has roots $1$ and
$\tfrac13$.

## Usage

```ada
with Linear_Multistep_Methods; use Linear_Multistep_Methods;

--  y' = -y, y(0)=1 → y(1)≈e^{-1} via AB2 with RK4 bootstrap
declare
   Y : Real;
begin
   Y := Advance_AB2 (F_Decay'Access, 0.0, 1.0, 1.0, 80);
end;

--  Implicit AM2 / BDF on a stiff-ish linear decay
declare
   Cfg : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, Solver => Newton);
   Y : Real;
begin
   Y := Advance_BDF2
     (F_Stiff'Access, 0.0, 1.0, 0.2, 40, Cfg, DF_Stiff'Access);
end;
```

## API summary

| Symbol | Role |
| --- | --- |
| `ODE_Fn` / `Partial_Y_Fn` | $f$ and optional $\partial f/\partial y$ |
| `History` | Past $f$ (or $y$) values, index 1 = newest |
| `Method_Kind` | `AB2`…`AB4`, `AM2_Trapezoid`, `AM3`, `BDF1`, `BDF2` |
| `Method_Name` / `Is_Explicit` / `Is_Implicit` | Taxonomy queries |
| `Order` / `Step_Number` | Convergence order and $k$ |
| `Adams_Bashforth_2/3/4_Step` | Explicit multistep advances |
| `Adams_Moulton_2/3_Step` | Implicit AM (Newton / fixed-point) |
| `BDF1_Step` / `BDF2_Step` | Implicit BDF advances |
| `Advance_*` | Interval solvers with documented bootstrap |
| `AB*_Beta_*` / `AM*_Beta_*` / `BDF*_Alpha_*` | Classic coefficients |
| `Characteristic_Polynomial_Roots_OK` | Zero-stability check |
| `Exact_Exponential` / `Near` / `Abs_Error` | Helpers |
| `F_Decay` / `F_Growth` / `F_Stiff` / `F_Logistic` / `DF_*` | Sample RHS |
| `Invalid_Argument` | Domain / convergence errors |

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision.
- Scalar ODE only; no adaptive $h$, no PECE predictor–corrector pairs,
  no variable-order Nordsieck / VODE-style controllers.
- Bootstrap error pollutes the first few steps of `Advance_*`; for pure
  local-order experiments prefer seeded `*_Step` calls with exact history.
- Explicit Adams–Bashforth methods are not A-stable; use AM / BDF for
  stiff problems (still educational Newton, not production DASPK).

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Plinear_multistep_methods.gpr
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
| `linear_multistep_methods.ads` | Package spec |
| `linear_multistep_methods.adb` | Package body |
| `linear_multistep_methods.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Linear multistep method](https://en.wikipedia.org/wiki/Linear_multistep_method)
- [Ada-Euler-Integration](https://github.com/RobertBoettcherSF/Ada-Euler-Integration) (sibling)
- [Ada-Runge-Kutta](https://github.com/RobertBoettcherSF/Ada-Runge-Kutta) (sibling)
- [Ada-Trapezoidal-Rule-DE](https://github.com/RobertBoettcherSF/Ada-Trapezoidal-Rule-DE) (sibling; AM2 overlap)
- Hairer, E.; Nørsett, S. P.; Wanner, G. *Solving Ordinary Differential Equations I*.
- Butcher, J. C. *Numerical Methods for Ordinary Differential Equations*.
- Iserles, A. (1996). *A First Course in the Numerical Analysis of Differential Equations*.
- Dahlquist, G. (1963). A special stability problem for linear multistep methods.
